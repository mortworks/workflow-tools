#!/usr/bin/env bash

# ---------------------------------------------------------
# 📝 Git auto-commit helper
# Supports: multiple files and custom message with -m
# ---------------------------------------------------------

FILES=()
COMMIT_MSG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      shift
      COMMIT_MSG="$1"
      ;;
    *)
      FILES+=("$1")
      ;;
  esac
  shift
done

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "❌ No files provided to commit."
  exit 1
fi

for file in "${FILES[@]}"; do
  if [[ ! -e "$file" ]]; then
    echo "⚠️  File not found (skipped): $file"
    continue
  fi
  echo "➕ Staging: $file"
  git add "$file"
done

if [[ -z "$COMMIT_MSG" ]]; then
  COMMIT_MSG="Update post(s): ${FILES[*]}"
fi

echo "✅ Committing with message: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"
git push && echo "🚀 Pushed to remote"
