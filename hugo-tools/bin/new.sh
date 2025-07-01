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

echo "✏️  Enter a custom slug or press Enter to use: $SLUG_DEFAULT"
read -r SLUG
SLUG="${SLUG:-$SLUG_DEFAULT}"

# Filename logic (based on slug but shorter + no stopwords)
STOPWORDS=(a the some)
FILENAME=$(echo "$SLUG" | tr '-' '\n' | grep -vwF "${STOPWORDS[@]}" | head -n 5 | paste -sd- -)
FILENAME=${FILENAME:0:20}  # truncate to 20 chars max

echo "🔢  Enter a custom filename or press Enter to use: $FILENAME.md"
read -r FILENAME_INPUT
FILENAME="${FILENAME_INPUT:-$FILENAME}"
POST_PATH="$CONTENT_DIR/$FILENAME.md"

# ----------------------------------------
# 📚 Read available templates from templates.yaml
# ----------------------------------------
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "❌ Error: templates.yaml not found at $TEMPLATE_FILE"
  exit 1
fi

TEMPLATES=( $(yq eval 'keys | .[]' "$TEMPLATE_FILE") )
echo "🧩 Choose a post type:"
for i in "${!TEMPLATES[@]}"; do
  printf "  %2d) %s\n" "$((i+1))" "${TEMPLATES[$i]}"
done
echo "Enter a number [1]:"
read -r CHOICE
INDEX=$(( (CHOICE > 0 ? CHOICE : 1) - 1 ))
POST_TYPE="${TEMPLATES[$INDEX]}"

# ----------------------------------------
# 🛠 Build front matter + placeholder anchors
# ----------------------------------------
DATE=$(date +"%Y-%m-%dT%H:%M:%S")

# Merge YAML template and inject values directly using mikefarah/yq syntax
FRONT_MATTER=$(yq eval \
  ".[\"$POST_TYPE\"] | .title=\"$TITLE\" | .date=\"$DATE\" | .draft=true | .slug=\"$SLUG\"" \
  "$TEMPLATE_FILE")

STRUCTURE_REFS=( $(yq eval ".${POST_TYPE}.structure[].ref" "$TEMPLATE_FILE") )

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

# Optionally open in editor
echo "📝 Open in editor now? [y/N]"
read -r OPEN
if [[ "$OPEN" =~ ^[Yy]$ ]]; then
  "${EDITOR:-nano}" "$POST_PATH"
fi
