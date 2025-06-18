#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

get_mtime() {
  if stat --version >/dev/null 2>&1; then
    stat -c '%Y' "$1"  # GNU (Linux)
  else
    stat -f '%m' "$1"  # BSD/macOS
  fi
}

get_post_path() {
  local slug="$1"
  echo "${CONTENT_DIR%/}/$slug.md"
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
      local draft=$(extract_draft "$file")
      local date=$(extract_date "$file")
      if [[ "$filter" == "published" && "$draft" == "true" ]]; then continue; fi
      if [[ "$filter" == "unpublished" && "$draft" != "true" ]]; then continue; fi

      # Only include files with valid date
      if [[ -n "$date" ]]; then
        echo "$date|$file"
      fi
    done |
    sort -r |
    cut -d'|' -f2 |
    head -n "$max"
}

display_menu_items() {
  local files=("$@")
  local index=1
  for file in "${files[@]}"; do
    local title=$(extract_title "$file")
    local date=$(extract_date "$file" | cut -d'T' -f1)
    local name=$(basename "$file")
    printf "%2d) %-10s  %s\n" "$index" "$date" "${title:-$name}"
    ((index++))
  done
}
