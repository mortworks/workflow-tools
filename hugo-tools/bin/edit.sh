#!/bin/bash

source "$(dirname "$0")/../lib/core.sh"

# Choose filter: published, unpublished, or all
echo "🗂️  What type of posts do you want to edit?"
echo "1) Unpublished"
echo "2) Published"
echo "3) All"
read -rp "Select (1-3): " choice

case "$choice" in
  1) filter="unpublished" ;;
  2) filter="published" ;;
  3) filter="all" ;;
  *) echo "Invalid option." && exit 1 ;;
esac

# Get recent posts
files=($(list_recent_files "$filter" "$MAX_RECENT"))

# Bail if no matches
if [[ ${#files[@]} -eq 0 ]]; then
  echo "🚫 No matching posts found."
  exit 0
fi

# Display menu
echo "📝 Select a file to edit:"
display_menu_items "${files[@]}"
read -rp "Choice: " selection

# Validate and edit
if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#files[@]} )); then
  selected_file="${files[$((selection - 1))]}"
  nano "$selected_file"

  # Ask whether to publish
  draft_status=$(extract_draft "$selected_file")
  if [[ "$draft_status" == "true" ]]; then
    read -rp "🚀 Publish this post now? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      sed -i 's/^draft *= *true/draft = false/' "$selected_file"
      git add "$selected_file"
      title=$(extract_title "$selected_file")
      git commit -m "📢 Publish post: $title"
      git push origin main
      echo "✅ Post published and pushed: $title"
    fi
  fi
else
  echo "❌ Invalid selection."
  exit 1
fi
