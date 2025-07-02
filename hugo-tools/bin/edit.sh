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

  if command -v code >/dev/null 2>&1; then
    echo "📝 Opening in VS Code: $file"
    code --wait "$file"
  elif [[ -n "$EDITOR" ]]; then
    echo "📝 Opening in editor defined by \$EDITOR: $file"
    "$EDITOR" "$file"
  else
    echo "📝 Opening in fallback editor (nano): $file"
    nano "$file"
  fi

  echo ""
  echo "✅ Finished editing. Commit changes? [y/N]"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    git add "$file"
    git commit -m "Edit post: $(basename "$file")"
    git push
    echo "✅ Changes committed and pushed."
  else
    echo "🚫 Changes not committed."
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

  matching_files=()
  while IFS= read -r -d '' file; do
    title=$(extract_title "$file")
    tags=$(extract_tags "$file")
    filename="$(basename "$file" .md)"
    combined="$title $tags $filename"
    score=$(match_score "$combined" "${terms[@]}")

    if [[ "$score" -gt 0 ]]; then
      matching_files+=("$file")
    fi
  done < <(find "$CONTENT_DIR" -name '*.md' -print0)

  if [[ ${#matching_files[@]} -eq 0 ]]; then
    echo "❌ No matches found."
  else
    echo ""
    display_menu_items "${matching_files[@]}"
    echo -n "Choose post number [1-${#matching_files[@]}]: "
    read -r num
    if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 1 && "$num" -le ${#matching_files[@]} ]]; then
      file="${matching_files[$((num - 1))]}"
      open_editor_and_commit "$file"
    else
      fatal "Invalid selection."
    fi
  fi

elif [[ "$input" =~ ^[0-9]+$ && "$input" -ge 1 && "$input" -le ${#recent_files[@]} ]]; then
  file="${recent_files[$((input - 1))]}"
  open_editor_and_commit "$file"

else
  fatal "Invalid input."
fi
