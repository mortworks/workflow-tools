#!/usr/bin/env bash

# hugo-tools/lib/utils.sh

fatal() {
  echo "❌ [ERROR] $1" >&2
  exit 1
}

generate_slug() {
  echo "$1" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/ /-/g' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | \
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
