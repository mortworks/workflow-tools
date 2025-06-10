#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/hugo.sh"

echo "📄 Enter a title for your new post:"
read -r title

slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')

POST_PATH=$(get_post_path "$slug")
create_post_file "$title" "$slug" "true"

echo "🔍 BLOG_ROOT=$BLOG_ROOT"
echo "🔍 CONTENT_DIR=$CONTENT_DIR"
echo "🔍 POST_PATH=$POST_PATH"

echo "🚀 Publish this post now? [y/N]"
read -r publish

if [[ "$publish" =~ ^[Yy]$ ]]; then
  sed -i.bak 's/draft = true/draft = false/' "$POST_PATH" && rm "$POST_PATH.bak"
  echo "✅ Post marked as published"
else
  echo "✅ Post created (still marked as draft)"
fi

# ----------------------------------------
# 🔁 Auto-commit via shared script
# ----------------------------------------

GIT_HELPER="$TOOLS_DIR/hugo-tools/bin/git-autocommit.sh"

if [[ -x "$GIT_HELPER" ]]; then
  "$GIT_HELPER" "$POST_PATH"
else
  echo "⚠️  git-autocommit.sh not found or not executable at: $GIT_HELPER"
  echo "💡 You can run this script manually later to commit:"
  echo "   $GIT_HELPER \"$POST_PATH\""
fi
