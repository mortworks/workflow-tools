#!/usr/bin/env bash

# new.sh — Create new Hugo post using YAML templates

# ----------------------------------------
# 📍 Environment setup
# ----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOG_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
TEMPLATE_FILE="$BLOG_ROOT/layouts/templates.yaml"
CONTENT_DIR="$BLOG_ROOT/content/posts"

# ----------------------------------------
# 🔗 Load shared metadata + utility helpers
# ----------------------------------------
LIB_DIR="$SCRIPT_DIR/../lib"

if [[ -f "$LIB_DIR/metadata.sh" ]]; then
  source "$LIB_DIR/metadata.sh"
else
  echo "❌ [ERROR] Could not load metadata helpers from $LIB_DIR/metadata.sh"
  exit 1
fi

if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  echo "❌ [ERROR] Could not load utility helpers from $LIB_DIR/utils.sh"
  exit 1
fi

# ----------------------------------------
# 🧠 Prompt for title + slug + filename
# ----------------------------------------
echo "📄 Enter a title for your new post:"
read -r TITLE

# Slug: lowercase, ASCII, hyphenated
SLUG_DEFAULT=$(echo "$TITLE" | \
  iconv -t ascii//TRANSLIT | \
  tr '[:upper:]' '[:lower:]' | \
  sed -E 's/[^a-z0-9]+/-/g' | \
  sed -E 's/^-+|-+$//g')

if [[ ${#SLUG_DEFAULT} -gt 40 ]]; then
  echo "⚠️ Auto-generated slug is quite long:"
  echo "   $SLUG_DEFAULT"
fi

echo "✏️  Enter a custom slug or press Enter to use: $SLUG_DEFAULT"
read -r SLUG
SLUG="${SLUG:-$SLUG_DEFAULT}"

# Sanitize again and enforce limit
SLUG=$(echo "$SLUG" | \
  iconv -t ascii//TRANSLIT | \
  tr '[:upper:]' '[:lower:]' | \
  sed -E 's/[^a-z0-9]+/-/g' | \
  sed -E 's/^-+|-+$//g')
SLUG="${SLUG:0:40}"

# Filename logic (based on slug but shorter + no stopwords)
STOPWORDS_RE="^(a|the|some)$"
FILENAME=$(echo "$SLUG" | tr '-' '\n' | awk "!/$STOPWORDS_RE/" | head -n 5 | paste -sd- -)
FILENAME=${FILENAME:30}  # truncate to 30 chars max

echo "🔢  Enter a custom filename or press Enter to use: $FILENAME.md"
read -r FILENAME_INPUT
FILENAME="${FILENAME_INPUT:-$FILENAME}"
POST_PATH="$CONTENT_DIR/$FILENAME.md"

# ----------------------------------------
# 📚 Load available templates
# ----------------------------------------

TEMPLATES=()
load_available_templates TEMPLATES

echo "🧩 Choose a post type:"
for i in "${!TEMPLATES[@]}"; do
  printf "  %2d) %s\n" "$((i+1))" "${TEMPLATES[$i]}"
done
echo "Enter a number [1]:"
read -r CHOICE
INDEX=$(( (CHOICE > 0 ? CHOICE : 1) - 1 ))
POST_TYPE="${TEMPLATES[$INDEX]}"

# ----------------------------------------
# 📄 Determine template file source
# ----------------------------------------

TEMPLATE_FILE=""
GLOBAL_TEMPLATE_FILE="$SCRIPT_DIR/../data/global-templates.yaml"
LOCAL_TEMPLATE_FILE="$BLOG_ROOT/data/templates.yaml"

if yq eval ".\"$POST_TYPE\"" "$LOCAL_TEMPLATE_FILE" &>/dev/null; then
  TEMPLATE_FILE="$LOCAL_TEMPLATE_FILE"
elif yq eval ".\"$POST_TYPE\"" "$GLOBAL_TEMPLATE_FILE" &>/dev/null; then
  TEMPLATE_FILE="$GLOBAL_TEMPLATE_FILE"
else
  fatal "Template '$POST_TYPE' not found in either template file."
fi

# ----------------------------------------
# 🛠 Build front matter + placeholder anchors
# ----------------------------------------
DATE=$(date +"%Y-%m-%dT%H:%M:%S")

# Merge YAML template and inject values directly using mikefarah/yq syntax
# Create a safe yq expression using envsubst
YQ_EXPR_FILE=$(mktemp)
TEMPLATE_EXPR_FILE=$(mktemp)

cat > "$TEMPLATE_EXPR_FILE" <<'EOF'
.${POST_TYPE} as $base |
. = {
  "title": "${TITLE}",
  "date": "${DATE}",
  "lastmod": "${DATE}",
  "published": "${DATE}",
  "draft": true,
  "slug": "${SLUG}",
  "layout": $base.layout,
  "structure": $base.structure,
  "anchors": $base.anchors
}
EOF

# Substitute variables safely
export TITLE DATE SLUG POST_TYPE
envsubst '${TITLE} ${DATE} ${SLUG} ${POST_TYPE}' < "$TEMPLATE_EXPR_FILE" > "$YQ_EXPR_FILE"

echo "----- YQ EXPRESSION -----"
cat "$YQ_EXPR_FILE"
echo "-------------------------"


# Evaluate YAML front matter
FRONT_MATTER=$(yq eval --from-file "$YQ_EXPR_FILE" "$TEMPLATE_FILE") || {
  echo "❌ [ERROR] Failed to generate front matter. Aborting."
  rm -f "$YQ_EXPR_FILE" "$TEMPLATE_EXPR_FILE"
  exit 1
}

rm -f "$YQ_EXPR_FILE" "$TEMPLATE_EXPR_FILE"

if yq eval ".${POST_TYPE}.structure" "$TEMPLATE_FILE" &>/dev/null; then
  STRUCTURE_REFS=( $(yq eval ".${POST_TYPE}.structure[].ref" "$TEMPLATE_FILE" 2>/dev/null) )
else
  STRUCTURE_REFS=()
fi

if [[ ${#STRUCTURE_REFS[@]} -eq 0 ]]; then
  echo "ℹ️  No structure refs found — skipping anchor injection."
fi

{
  echo "---"
  echo "$FRONT_MATTER"
  echo "---"
  echo ""
  for ref in "${STRUCTURE_REFS[@]}"; do
    echo "<!-- $ref -->"
    echo ""
  done
} > "$POST_PATH"

# ----------------------------------------
# ✅ Success
# ----------------------------------------
echo "✅ Post created: $POST_PATH"

# ----------------------------------------
# 🚀 Offer to publish
# ----------------------------------------
echo "🚀 Publish this post now? [y/N]"
read -r PUBLISH
if [[ "$PUBLISH" =~ ^[Yy]$ ]]; then
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Mark as not a draft
  sed -i.bak 's/^draft: true$/draft: false/' "$POST_PATH"

  # Update published field using yq
  if command -v yq >/dev/null 2>&1; then
    yq -i ".published = \"$NOW\"" "$POST_PATH"
  else
    echo "❌ 'yq' is required to update 'published' field but not found."
    exit 1
  fi

  # Use shared function to update lastmod
  update_lastmod_field "$POST_PATH"

  # Remove backup
  rm -f "$POST_PATH.bak"

  echo "✅ Post marked as published"
else
  echo "✅ Post created (still marked as draft)"
fi

# ----------------------------------------
# 💬 Optional Git auto-commit
# ----------------------------------------
GIT_HELPER="$SCRIPT_DIR/../lib/git-autocommit.sh"
if [[ -x "$GIT_HELPER" ]]; then
  "$GIT_HELPER" "$POST_PATH"
else
  echo "⚠️ git-autocommit.sh not found or not executable at: $GIT_HELPER"
  echo "💡 You can run this script manually later to commit:"
  echo "   $GIT_HELPER \"$POST_PATH\""
fi
