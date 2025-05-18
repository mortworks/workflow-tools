#!/bin/bash

# Load Hugo-related utilities
source "$(dirname "$0")/../lib/hugo.sh"

echo "📄 Enter a title for your new post:"
read -r title

# Generate slug from title
slug=$(generate_slug "$title")

# Confirm uniqueness
while [[ -f $(get_post_path "$slug") ]]; do
  echo "⚠️  A post with this slug already exists: $slug"
  echo "Enter a new slug:"
  read -r slug
  slug=$(generate_slug "$slug")
done

# Create post file
filepath=$(create_post_file "$title" "$slug" "true")

# Open in editor
nano "$filepath"

# Option to publish immediately
read -rp "🚀 Publish this post now? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  sed -i 's/^draft = true/draft = false/' "$filepath"
  echo "✅ Post published"
fi

# Git add, commit, push
git add "$filepath"
git commit -m "Add new post: $title"
git push origin main
echo "✅ Changes pushed to GitHub"
