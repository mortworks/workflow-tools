#!/bin/bash

# Load configuration
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.sh"

# --------------------------------------------
# 📆 Academic year handling (e.g., 2024–2025)
# --------------------------------------------
get_academic_year() {
  local today=$(date +%Y-%m-%d)
  local year=$(date +%Y)
  local cutoff_date="$year-$ACADEMIC_YEAR_START_MONTH-01"

  if [[ "$today" < "$cutoff_date" ]]; then
    local start_year=$((year - 1))
    local end_year=$year
  else
    local start_year=$year
    local end_year=$((year + 1))
  fi

  echo "$start_year-$end_year"
}

# --------------------------------------------
# 🛤️  Generate full path for a new post
# --------------------------------------------
get_post_path() {
  local slug="$1"
  local year_dir
  year_dir="$(get_academic_year)"
  echo "$CONTENT_DIR/$year_dir/$slug.md"
}

# --------------------------------------------
# 🧼 Front matter field extractors (TOML)
# --------------------------------------------
extract_title() {
  grep '^title' "$1" | sed 's/title *= *["'\'']\(.*\)["'\'']/\1/'
}

extract_date() {
  grep '^date' "$1" | sed 's/date *= *["'\'']\(.*\)["'\'']/\1/'
}

extract_draft() {
  grep '^draft' "$1" | sed 's/draft *= *\(true\|false\)/\1/'
}

# --------------------------------------------
# 🗃️ List recent Markdown files (by draft status)
# --------------------------------------------
list_recent_files() {
  local filter="$1"         # published, unpublished, or all
  local max="${2:-$MAX_RECENT}"

  find "$CONTENT_DIR" -name '*.md' -print0 |
    while IFS= read -r -d '' file; do
      local draft
      draft=$(extract_draft "$file")

      if [[ "$filter" == "published" && "$draft" == "true" ]]; then continue; fi
      if [[ "$filter" == "unpublished" && "$draft" != "true" ]]; then continue; fi

      echo "$file"
    done |
    while read -r f; do
      echo "$(stat -c '%Y %n' "$f")"
    done |
    sort -nr |
    cut -d' ' -f2- |
    head -n "$max"
}

# --------------------------------------------
# 📋 Display post menu (title + date)
# --------------------------------------------
display_menu_items() {
  local files=("$@")
  local index=1
  for file in "${files[@]}"; do
    local title=$(extract_title "$file")
    local date=$(extract_date "$file")
    echo "$index) [$date] $title"
    ((index++))
  done
}
