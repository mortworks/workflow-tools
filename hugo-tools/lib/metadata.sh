#!/usr/bin/env bash

# metadata.sh — Extract YAML front matter metadata from Hugo post files

# Ensure file exists before trying to parse
assert_file_exists() {
  if [[ ! -f "$1" ]]; then
    echo "❌ File not found: $1"
    return 1
  fi
}

extract_title() {
  grep -i '^title:' "$1" | sed -E 's/^title:[[:space:]]*["'\'']?(.*?)["'\'']?$/\1/'
}

extract_date() {
  grep -i '^date:' "$1" | sed -E 's/^date:[[:space:]]*["'\'']?(.*?)["'\'']?$/\1/'
}

extract_draft() {
  grep -i '^draft:' "$1" | sed -E 's/^draft:[[:space:]]*(true|false)/\1/I'
}

extract_tags() {
  grep -i '^tags:' "$1" | sed -E 's/^tags:[[:space:]]*\[(.*)\]/\1/' | tr -d '"'
}

