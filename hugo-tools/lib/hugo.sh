#!/bin/bash

source "$(dirname "$0")/core.sh"

# Convert title to slug
generate_slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g'
}

# Generate front matter (TOML format)
generate_front_matter() {
  local title="$1"
  local date="$2"
  local slug="$3"
  local draft="${4:-true}"  # default is draft = true

  cat <<EOF
+++
title = "$title"
date = "$date"
draft = $draft
url = "/$slug/"
type = "post"
+++

EOF
}

# Create a new post file with Hugo's structure
create_post_file() {
  local title="$1"
  local slug="$2"
  local draft="$3"
  local year_dir
  year_dir="$(get_academic_year)"

  local post_path="$CONTENT_DIR/$year_dir/$slug.md"
  mkdir -p "$(dirname "$post_path")"

  local date="$(date +'%Y-%m-%dT%H:%M:%S')"
  generate_front_matter "$title" "$date" "$slug" "$draft" > "$post_path"

  echo "$post_path"
}
