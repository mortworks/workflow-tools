#!/usr/bin/env bash

# ---------------------------------------------------------
# 🚀 Hugo new post script
# ---------------------------------------------------------

# Resolve the real path, even if this script is symlinked
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Load error helpers
if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  echo "❌ [ERROR] Could not load error helpers from $LIB_DIR/utils.sh"
  exit 1
fi

# Load Hugo environment
if ! source "$LIB_DIR/hugo.sh"; then
  fatal "Aborting: could not load Hugo environment."
fi

# ---------------------------------------------------------
# 📝 Create the post
# ---------------------------------------------------------

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

# ---------------------------------------------------------
# 💬 Offer to auto-commit
# ---------------------------------------------------------

GIT_HELPER="$TOOLS_DIR/hugo-tools/bin/git-autocommit.sh"
if [[ -x "$GIT_HELPER" ]]; then
  "$GIT_HELPER" "$POST_PATH"
else
  echo "⚠️  git-autocommit.sh not found or not executable at: $GIT_HELPER"
  echo "💡 You can run this script manually later to commit:"
  echo "   $GIT_HELPER \"$POST_PATH\""
fi
