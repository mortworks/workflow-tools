#!/usr/bin/env bash

# ---------------------------------------------------------
# 💬 Git auto-commit helper
# ---------------------------------------------------------

commit_msg=""
files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      shift
      commit_msg="$1"
      ;;
    *)
      files+=("$1")
      ;;
  esac
  shift
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "❌ No files provided."
  exit 1
fi

echo "📝 Committing ${#files[@]} file(s)..."

for file in "${files[@]}"; do
  if [[ -e "$file" ]]; then
    git add "$file"
  else
    git rm --quiet "$file" 2>/dev/null || echo "⚠️  File not tracked or already deleted: $file"
  fi
done

default_message="Update ${#files[@]} file(s)"
final_message="${commit_msg:-$default_message}"

echo "📦 Commit message: $final_message"
git commit -m "$final_message"
git push && echo "✅ Pushed to remote"
