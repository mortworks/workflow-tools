#!/usr/bin/env bash

# Resolve the current script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source core logic and config
if [[ -f "$SCRIPT_DIR/core.sh" ]]; then
  source "$SCRIPT_DIR/core.sh"
else
  fatal "❌ core.sh not found in $SCRIPT_DIR"
  return 1 2>/dev/null || exit 1
fi

# Generate front matter for new post
generate_front_matter() {
  local title="$1"
  local date="$2"
  local slug="$3"
  local draft="$4"

  cat <<EOF
+++
title = "$title"
date = "$date"
draft = $draft
slug = "$slug"
+++
EOF
}

# Create the file and return its path
create_post_file() {
  local title="$1"
  local slug="$2"
  local draft="$3"
  local post_path="$CONTENT_DIR/$slug.md"

  mkdir -p "$(dirname "$post_path")"
  local date="$(date +'%Y-%m-%dT%H:%M:%S')"
  generate_front_matter "$title" "$date" "$slug" "$draft" > "$post_path"
  echo "$post_path"
}
