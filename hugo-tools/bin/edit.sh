#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/hugo.sh"

echo "📝 Edit mode — select a post to open"

# Get the list of recent posts
mapfile -t posts < <(list_recent_files)

if [[ ${#posts[@]} -eq 0 ]]; then
  echo "⚠️  No posts found to edit."
  exit 1
fi

display_menu_items "${posts[@]}"

read -rp "Choose a number: " selection

if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#posts[@]} )); then
  echo "❌ Invalid selection"
  exit 1
fi

file="${posts[$((selection-1))]}"
echo "📂 Opening: $file"
sleep 0.3

"${EDITOR:-nano}" "$file"
