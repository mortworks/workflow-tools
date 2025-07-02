#!/usr/bin/env bash

# ---------------------------------------------------------
# 🧰 hugo-tools/lib/utils.sh — shared utility functions
# ---------------------------------------------------------

# ---------------------------------------------------------
# 🕒 Cross-platform file mtime
# ---------------------------------------------------------
get_mtime() {
  local file="$1"
  if stat --version >/dev/null 2>&1; then
    # Linux / GNU stat
    stat -c "%Y" "$file"
  else
    # macOS / BSD stat
    stat -f "%m" "$file"
  fi
}

# ---------------------------------------------------------
# 📦 Load shared metadata helpers
# ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR"

if [[ -f "$LIB_DIR/metadata.sh" ]]; then
  source "$LIB_DIR/metadata.sh"
else
  echo "❌ [ERROR] Could not load metadata.sh from $LIB_DIR"
  exit 1
fi

fatal() {
  echo "❌ [ERROR] $1" >&2
  exit 1
}

generate_slug() {
  echo "$1" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/ /-/g' | \
    sed 's/[^a-z0-9-]//g' | \
    sed 's/--*/-/g' | \
    cut -c1-40
}

get_post_path() {
  local slug="$1"
  echo "${CONTENT_DIR%/}/$slug.md"
}

update_post_slug() {
  local file="$1"
  local old_slug
  old_slug=$(basename "$file" .md)

  echo ""
  echo "🔧 Current slug: $old_slug"
  echo "✏️  Enter a new slug (max 40 chars) or press Enter to keep:"
  read -r user_input

  if [[ -z "$user_input" ]]; then
    echo "✅ Slug unchanged."
    UPDATED_POST_PATH="$file"
    return 0
  fi

  local new_slug
  new_slug="$(generate_slug "$user_input")"

  if [[ -z "$new_slug" ]]; then
    echo "❌ Invalid slug. Aborting slug update."
    UPDATED_POST_PATH="$file"
    return 1
  fi

  local new_file
  new_file="$(dirname "$file")/$new_slug.md"

  mv "$file" "$new_file"
  sed -i.bak "s/^slug: .*/slug: \"$new_slug\"/" "$new_file" && rm "$new_file.bak"

  echo "✅ Slug updated to: $new_slug"
  echo "📄 File renamed to: $(basename "$new_file")"

  UPDATED_POST_PATH="$new_file"
}

# ---------------------------------------------------------
# 📄 List recent posts (excludes _index.md)
# ---------------------------------------------------------
load_recent_posts() {
  local limit="$1"
  local -n result_ref="$2"

  result_ref=()
  while IFS= read -r line; do
    result_ref+=("$line")
  done < <(list_recent_posts "$limit")
}

# ---------------------------------------------------------
# 📁 list_recent_posts — list recent Markdown posts
# ---------------------------------------------------------
list_recent_posts() {
  local mode="${1:-all}"
  local count="${2:-10}"
  local content_dir="$CONTENT_DIR"

  if [[ -z "$content_dir" ]]; then
    fatal "CONTENT_DIR is not set"
  fi

  local files
  if [[ "$mode" == "drafts" ]]; then
    files=$(find "$content_dir" -type f -name '*.md' ! -name '_index.md' -exec grep -l '^draft: true' {} + 2>/dev/null)
  else
    files=$(find "$content_dir" -type f -name '*.md' ! -name '_index.md' 2>/dev/null)
  fi

  echo "$files" | while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      local full_date
      full_date=$(yq eval '.date' "$file" 2>/dev/null)
      if [[ "$full_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        sortable=$(echo "$full_date" | sed -E 's/[-:]//g' | sed 's/T//')
        printf "%s\t%s\n" "$sortable" "$file"
      fi
    fi
  done | LC_ALL=C sort -t$'\t' -k1,1nr | cut -f2- | head -n "$count"
}

# ---------------------------------------------------------
# 📋 display_menu_items — nice listing of posts
# ---------------------------------------------------------
display_menu_items() {
  local -a files=("$@")
  local index=1
  for file in "${files[@]}"; do
    local title=$(extract_title "$file")
    local date=$(extract_date "$file")
    local draft=$(extract_draft "$file")

    [[ "$draft" == "true" ]] && draft="[DRAFT]" || draft=""
    [[ -z "$date" ]] && date="??-??-????"

    printf "  %2d) %-10s [%-10s] %s [%s]\n" \
      "$index" "$draft" "$date" "$title" "$(basename "$file")"
    ((index++))
  done
}
