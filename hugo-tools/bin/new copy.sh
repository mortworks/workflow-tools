#!/usr/bin/env bash

# ---------------------------------------------------------
# 🚀 Hugo new post script
# ---------------------------------------------------------

# Resolve real path (support symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Load utilities
if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  echo "❌ [ERROR] Could not load utilities from $LIB_DIR/utils.sh"
  exit 1
fi

# Load Hugo environment
if ! source "$LIB_DIR/hugo.sh" || [[ -z "$HUGO_ENV_OK" ]]; then
  fatal "Aborting: could not load Hugo environment."
fi

# ---------------------------------------------------------
# 📝 Collect title and generate slug
# ---------------------------------------------------------

echo "📄 Enter a title for your new post:"
read -r title

default_slug="$(generate_slug "$title")"

if [[ "${#default_slug}" -gt 40 ]]; then
  echo "⚠️  Auto-generated slug is quite long:"
  echo "   $default_slug"
fi

echo -n "✏️  Enter a custom slug or press Enter to use: $default_slug
> "
read -r user_slug

slug="${user_slug:-$default_slug}"
slug="$(generate_slug "$slug")"
slug="${slug:0:40}"

# ---------------------------------------------------------
# 📝 Create post
# ---------------------------------------------------------

POST_PATH=$(get_post_path "$slug")
create_post_file "$title" "$slug" "true"

echo "🔍 BLOG_ROOT=$BLOG_ROOT"
echo "🔍 CONTENT_DIR=$CONTENT_DIR"
echo "🔍 POST_PATH=$POST_PATH"

# ---------------------------------------------------------
# 🚀 Offer publication
# ---------------------------------------------------------

echo "🚀 Publish this post now? [y/N]"
read -r publish

if [[ "$publish" =~ ^[Yy]$ ]]; then
  sed -i.bak 's/draft = true/draft = false/' "$POST_PATH" && rm "$POST_PATH.bak"
  echo "✅ Post marked as published"
else
  echo "✅ Post created (still marked as draft)"
fi

# ---------------------------------------------------------
# 💬 Offer to auto-commit
# ---------------------------------------------------------

GIT_HELPER="$LIB_DIR/git-autocommit.sh"
if [[ -x "$GIT_HELPER" ]]; then
  "$GIT_HELPER" "$POST_PATH"
else
  echo "⚠️  git-autocommit.sh not found or not executable at: $GIT_HELPER"
  echo "💡 You can run this script manually later to commit:"
  echo "   $GIT_HELPER \"$POST_PATH\""
fi
