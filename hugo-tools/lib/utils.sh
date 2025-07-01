#!/usr/bin/env bash

# ---------------------------------------------------------
# 🧰 hugo-tools/lib/utils.sh — shared utility functions
# ---------------------------------------------------------

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

  # Rename the file and update the front matter (YAML)
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
  local -n result_ref="$2"  # Use nameref to pass array by reference

  result_ref=()
  while IFS= read -r line; do
    result_ref+=("$line")
  done < <(list_recent_posts "$limit")
}

list_recent_posts() {
  local count="${1:-10}"
  find "$CONTENT_DIR" -type f -name '*.md' ! -name '_index.md' -print0 2>/dev/null |
    xargs -0 stat -f "%m %N" 2>/dev/null |
    sort -rn |
    head -n "$count" |
    cut -d' ' -f2-
}

display_menu_items() {
  local -a files=("$@")
  local index=1
  for file in "${files[@]}"; do
    local title date draft

    title=$(awk -F': ' '/^title:/{print $2; exit}' "$file" | tr -d '"' | xargs)
    date=$(awk -F': ' '/^date:/{print $2; exit}' "$file" | tr -d '"' | xargs)
    draft=$(awk -F': ' '/^draft:/{print $2; exit}' "$file" | tr -d '"' | xargs)

    local label="[$date] $title"
    [[ "$draft" == "true" ]] && label="[DRAFT] $label"

    printf "  %2d) %s [%s]\n" "$index" "$label" "$(basename "$file")"
    ((index++))
  done
}

