#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

get_post_path() {
  local slug="$1"
  local post_path="${CONTENT_DIR%/}/$slug.md"
}

extract_title() {
  grep '^title' "$1" | sed 's/title *= *["'"'"']\(.*\)["'"'"']/\1/'
}

extract_date() {
  grep '^date' "$1" | sed 's/date *= *["'"'"']\(.*\)["'"'"']/\1/'
}

extract_draft() {
  grep '^draft' "$1" | sed 's/draft *= *\([a-z]*\)/\1/'
}

list_recent_files() {
  local filter="$1"
  local max="${2:-10}"

  find "$CONTENT_DIR" -name '*.md' -print0 |
    while IFS= read -r -d '' file; do
      local draft
      draft=$(extract_draft "$file")
      if [[ "$filter" == "published" && "$draft" == "true" ]]; then continue; fi
      if [[ "$filter" == "unpublished" && "$draft" != "true" ]]; then continue; fi
      echo "$file"
    done |
    while read -r f; do
      echo "$(stat -f '%m %N' "$f")"
    done |
    sort -nr |
    cut -d' ' -f2- |
    head -n "$max"
}

display_menu_items() {
  local files=("$@")
  local index=1
  for file in "${files[@]}"; do
    local title=$(extract_title "$file")
    local date=$(extract_date "$file")
    echo "$index\) [$date] $title"
    ((index++))
  done
}
