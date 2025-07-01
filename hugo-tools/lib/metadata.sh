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
  local file="$1"
  assert_file_exists "$file" || return 1
  grep '^title:' "$file" | sed 's/title:[ ]*["'"'"']\{0,1\}\(.*\)["'"'"']\{0,1\}/\1/'
}

extract_date() {
  local file="$1"
  assert_file_exists "$file" || return 1
  grep '^date:' "$file" | sed 's/date:[ ]*["'"'"']\{0,1\}\(.*\)["'"'"']\{0,1\}/\1/'
}

extract_draft() {
  local file="$1"
  assert_file_exists "$file" || return 1
  grep '^draft:' "$file" | sed 's/draft:[ ]*\([a-z]*\)/\1/'
}

extract_tags() {
  local file="$1"
  assert_file_exists "$file" || return 1
  grep '^tags:' "$file" | sed 's/tags:[ ]*\[\(.*\)\]/\1/' | tr -d '"'
}
