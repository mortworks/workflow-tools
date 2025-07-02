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
  awk -F': *' '
    $1 == "title" {
      gsub(/^["'\''"]|["'\''"]$/, "", $2); print $2; exit
    }
  ' "$file"
}

extract_date() {
  local file="$1"
  local raw_date

  raw_date=$(grep '^date:' "$file" | head -n1 | sed 's/^date:[[:space:]]*["'\''"]\{0,1\}//;s/["'\''"]\{0,1\}$//')

  if [[ -z "$raw_date" ]]; then
    echo "??-??-????"
    return
  fi

  # Detect platform
  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    date -d "$raw_date" '+%d-%m-%Y' 2>/dev/null || echo "$raw_date"
  else
    # BSD date (macOS)
    date -j -f '%Y-%m-%dT%H:%M:%S' "$raw_date" '+%d-%m-%Y' 2>/dev/null || \
    date -j -f '%Y-%m-%d' "$raw_date" '+%d-%m-%Y' 2>/dev/null || \
    echo "$raw_date"
  fi
}


extract_draft() {
  grep -i '^draft:' "$1" | sed -E 's/^draft:[[:space:]]*(true|false)/\1/I'
}

extract_tags() {
  grep -E '^tags:' "$1" | head -n 1 | sed -E 's/^tags:[[:space:]]*\[?(.*)\]?/\1/' | tr -d '"'\''[:space:]'
}

