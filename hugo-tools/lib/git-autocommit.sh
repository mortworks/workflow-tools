#!/usr/bin/env bash

# ---------------------------------------------------------
# 💬 Git auto-commit helper
# ---------------------------------------------------------

commit_msg=""
files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message|--msg|--message=*)
      if [[ "$1" == *=* ]]; then
        commit_msg="${1#*=}"
      else
        shift
        commit_msg="$1"
      fi
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

default_message="Auto-commit: changed ${#files[@]} file(s)"
message="${commit_msg:-$default_message}"

echo "📦 Commit message: $message"
safe_message=$(echo "$message" | tr -d '"')
git commit -m "$safe_message"
git push && echo "✅ Pushed to remote"remote"
