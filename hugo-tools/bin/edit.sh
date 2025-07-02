#!/usr/bin/env bash

# ---------------------------------------------------------
# 📜 Hugo edit post script (YAML-compatible)
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Load shared utils and fatal()
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
# 🔍 Helpers
# ---------------------------------------------------------

match_score() {
  local text="$1"
  shift
  local terms=("$@")
  local score=0
  for term in "${terms[@]}"; do
    if echo "$text" | grep -qi "$term"; then
      ((score++))
    fi
  done
  echo "$score"
}

open_editor_and_commit() {
  local file="$1"

  echo "📝 Opening: $file"
  "${EDITOR:-nano}" "$file"

  echo ""
  echo "✏️  Would you like to update the slug and filename? [y/N]"
  read -r update_slug
  if [[ "$update_slug" =~ ^[Yy]$ ]]; then
    update_post_slug "$file"
    file="$UPDATED_POST_PATH"
  fi

  echo ""
  echo "🚀 Commit and push this change? [y/N]"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    local GIT_HELPER="$LIB_DIR/git-autocommit.sh"
    if [[ -x "$GIT_HELPER" ]]; then
      "$GIT_HELPER" "$file"
    else
      echo "⚠️  git-autocommit.sh not found at $GIT_HELPER"
    fi
  else
    echo "💡 You can commit manually later:"
    echo "   git add \"$file\" && git commit && git push"
  fi
}

# ---------------------------------------------------------
# 🚀 Main logic
# ---------------------------------------------------------

echo "📜 Edit mode — recent posts + search options"
echo "📚 Loading recent posts (all)..."

recent_files=()
while IFS= read -r line; do
  recent_files+=("$line")
done < <(list_recent_posts "all" 10)

echo ""
display_menu_items "${recent_files[@]}"
echo ""
echo "Type a number to edit a post"
echo "Or enter one of the following:"
echo "  s → 🔍 search by title/tag"
echo "  a → 📋 show all posts"
echo "  q → ❌ quit"
echo -n "> "
read -r input

if [[ "$input" == "q" ]]; then
  echo "👋 Exiting."
  exit 0

elif [[ "$input" == "a" ]]; then
  echo "📜 Listing all posts..."
  all_files=()
  while IFS= read -r line; do
    all_files+=("$line")
  done < <(list_recent_posts "all" 100)

  echo ""
  display_menu_items "${all_files[@]}"
  echo -n "Choose post number [1-${#all_files[@]}]: "
  read -r num
  if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 1 && "$num" -le ${#all_files[@]} ]]; then
    file="${all_files[$((num - 1))]}"
    open_editor_and_commit "$file"
  else
    fatal "Invalid selection."
  fi

elif [[ "$input" == "s" ]]; then
  echo -n "🔍 Search for post by title or tag: "
  read -r query
  IFS=' ' read -r -a terms <<< "$query"

  tmpfile=$(mktemp)
  while IFS= read -r -d '' file; do
    title=$(extract_title "$file")
    tags=$(extract_tags "$file")
    filename="$(basename "$file" .md)"
    combined="$title $tags $filename"
    score=$(match_score "$combined" "${terms[@]}")

    if [[ "$score" -gt 0 ]]; then
      printf "%d\t%s\t%s\n" "$score" "$(get_mtime "$file")" "$file" >> "$tmpfile"
    fi
  done < <(find "$CONTENT_DIR" -name '*.md' -print0)

  sorted_matches=()
  while IFS=$'\t' read -r score mtime file; do
    sorted_matches+=("$file")
  done < <(sort -t$'\t' -k1,1nr -k2,2nr "$tmpfile")
  rm -f "$tmpfile"

  echo ""
  echo "🎯 Matching posts:"
  display_menu_items "${sorted_matches[@]}"
  echo -n "Choose post number [1-${#sorted_matches[@]}]: "
  read -r num
  if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 1 && "$num" -le ${#sorted_matches[@]} ]]; then
    file="${sorted_matches[$((num - 1))]}"
    open_editor_and_commit "$file"
  else
    fatal "Invalid selection."
  fi

elif [[ "$input" =~ ^[0-9]+$ && "$input" -ge 1 && "$input" -le ${#recent_files[@]} ]]; then
  file="${recent_files[$((input - 1))]}"
  open_editor_and_commit "$file"

else
  fatal "Invalid input."
fi
