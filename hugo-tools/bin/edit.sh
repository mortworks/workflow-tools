#!/usr/bin/env bash

WRAPPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$WRAPPER_DIR/../lib/hugo.sh"

filter="all"
if [[ "$1" == "--drafts" ]]; then
  filter="unpublished"
elif [[ "$1" == "--published" ]]; then
  filter="published"
fi

echo "📝 Edit mode — select a post to open"
echo "📚 Fetching recent posts ($filter)..."
files=()
while IFS= read -r line; do
  files+=("$line")
done < <(list_recent_files "$filter")

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "❌ No posts found for filter: $filter"
  exit 1
fi

display_menu_items "${files[@]}"
echo -n "Choose a post to edit [1-${#files[@]}]: "
read -r choice

if [[ "$choice" -lt 1 || "$choice" -gt "${#files[@]}" ]]; then
  echo "❌ Invalid selection."
  exit 1
fi

file="${files[$((choice - 1))]}"
echo "📝 Opening: $file"
"${EDITOR:-nano}" "$file"

# ✅ Ask to commit after edit
echo ""
echo "🚀 Commit and push this change? [y/N]"
read -r confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  GIT_HELPER="$WRAPPER_DIR/git-autocommit.sh"
  if [[ -x "$GIT_HELPER" ]]; then
    "$GIT_HELPER" "$file"
  else
    echo "⚠️  git-autocommit.sh not found at $GIT_HELPER"
  fi
else
  echo "💡 You can commit manually later using:"
  echo "   git add \"$file\" && git commit && git push"
fi
