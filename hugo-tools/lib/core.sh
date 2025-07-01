#!/usr/bin/env bash

# hugo-tools/lib/core.sh

# Resolve the current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config
source "$SCRIPT_DIR/config.sh"

# Generate front matter in YAML format
generate_front_matter() {
  local title="$1"
  local date="$2"
  local slug="$3"
  local draft="$4"

  cat <<EOF
---
title: "$title"
date: "$date"
draft: $draft
slug: "$slug"
type: posts
---
EOF
}

# Create the file and return its path
create_post_file() {
  local title="$1"
  local slug="$2"
  local draft="$3"
  local post_path="$CONTENT_DIR/$slug.md"

  mkdir -p "$(dirname "$post_path")"
  local date="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  generate_front_matter "$title" "$date" "$slug" "$draft" > "$post_path"
  echo "$post_path"
}

