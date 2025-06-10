#!/usr/bin/env bash

file="$1"

if [[ ! -f "$file" ]]; then
  echo "❌ File not found: $file"
  exit 1
fi

echo "📝 Committing: $file"
default_message="Update post: $(basename "$file")"
read -rp "Enter commit message [${default_message}]: " message
message="${message:-$default_message}"

git add "$file"
git commit -m "$message"
git push && echo "✅ Pushed to remote"
