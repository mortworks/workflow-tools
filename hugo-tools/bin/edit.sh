#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/hugo.sh"

# ----------------------------------------
# 🔍 Extract tags from frontmatter
# ----------------------------------------
extract_tags() {
  grep '^tags' "$1" | sed 's/tags *= *\[\(.*\)\]/\1/' | tr -d '"'
}

# ----------------------------------------
# 📊 Calculate match score for search term
# ----------------------------------------
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

# ----------------------------------------
# 📋 Display post list menu
# ----------------------------------------
display_menu_items() {
  local -a files=("$@")
  local index=1
  for file in "${files[@]}"; do
    local title=$(extract_title "$file")
    local date=$(extract_date "$file")
    local draft=$(extract_draft "$file")
    local label="[$date] $title"
    [[ "$draft" == "true" ]] && label="[DRAFT] $label"
    printf "  %d) %s\n" "$index" "$label"
    ((index++))
  done
}

# ----------------------------------------
# 🚀 Edit selected file and optionally commit
# ----------------------------------------
open_editor_and_commit() {
  local file="$1"
  echo "📝 Opening: $file"
  "${EDITOR:-nano}" "$file"

  echo ""
  echo "🚀 Commit and push this change? [y/N]"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    GIT_HELPER="$SCRIPT_DIR/git-autocommit.sh"
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

# ----------------------------------------
# 📝 Main logic
# ----------------------------------------

echo "📝 Edit mode — recent posts + search options"
echo "📚 Loading recent posts (all)..."
recent_files=()
while IFS= read -r line; do
  recent_files+=("$line")
done < <(list_recent_files "all" 10)

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
  echo ""
  echo "📜 All posts:"
  all_files=()
  while IFS= read -r line; do
    all_files+=("$line")
  done < <(list_recent_files "all" 500)

  display_menu_items "${all_files[@]}"
  echo -n "Choose post number [1-${#all_files[@]}]: "
  read -r num
  if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 1 && "$num" -le ${#all_files[@]} ]]; then
    file="${all_files[$((num - 1))]}"
    open_editor_and_commit "$file"
  else
    echo "❌ Invalid selection."
    exit 1
  fi
  exit 0
elif [[ "$input" == "s" ]]; then
  echo -n "🔍 Search for post by title or tag: "
  read -r query
  IFS=' ' read -r -a terms <<< "$query"

matches=()
scored_lines=()

for file in $(find "$CONTENT_DIR" -name '*.md'); do
  title=$(extract_title "$file")
  tags=$(extract_tags "$file")
  combined="$title $tags"
  score=0

  for term in "${terms[@]}"; do
    if echo "$combined" | grep -qi "$term"; then
      ((score++))
    fi
  done

  if [[ "$score" -gt 0 ]]; then
    scored_lines+=("$score $(stat -f '%m' "$file") $file")
  fi
done

# Sort results by score then mtime
sorted_matches=($(printf "%s\n" "${scored_lines[@]}" | sort -k1,1nr -k2,2nr | cut -d' ' -f3-))

  echo ""
  echo "🎯 Matching posts:"
  display_menu_items "${sorted_matches[@]}"
  echo -n "Choose post number [1-${#sorted_matches[@]}]: "
  read -r num
  if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 1 && "$num" -le ${#sorted_matches[@]} ]]; then
    file="${sorted_matches[$((num - 1))]}"
    open_editor_and_commit "$file"
  else
    echo "❌ Invalid selection."
    exit 1
  fi
  exit 0
elif [[ "$input" =~ ^[0-9]+$ && "$input" -ge 1 && "$input" -le ${#recent_files[@]} ]]; then
  file="${recent_files[$((input - 1))]}"
  open_editor_and_commit "$file"
else
  echo "❌ Invalid input."
  exit 1
fi
