#!/usr/bin/env bash

# ---------------------------------------------------------
# 🌱 Configure Hugo blog environment for multiple blog repos
# ---------------------------------------------------------

# Acceptable Hugo config filenames
HUGO_CONFIG_FILES=("hugo.toml" "config.toml" "config.yaml" "hugo.yaml")

# Check if any Hugo config file exists in a given directory
has_hugo_config() {
  local dir="$1"
  for file in "${HUGO_CONFIG_FILES[@]}"; do
    [[ -f "$dir/$file" ]] && return 0
  done
  return 1
}

# Attempt to find the Hugo root by walking up to find a valid config file
find_hugo_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if has_hugo_config "$dir"; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
}

# Resolve root directory for current blog
BLOG_ROOT="$(find_hugo_root)"

if [[ -z "$BLOG_ROOT" ]]; then
  echo "❌ Could not locate a Hugo site (no supported config file found)."
  return 1 2>/dev/null || exit 1
fi

# Optional: allow override with .blogrc
if [[ -f "$BLOG_ROOT/.blogrc" ]]; then
  source "$BLOG_ROOT/.blogrc"
fi

# Fallbacks if not set in .blogrc
CONTENT_DIR="${CONTENT_DIR:-$BLOG_ROOT/content/posts}"
DRAFT_DIR="${DRAFT_DIR:-$BLOG_ROOT/_drafts}"

# ---------------------------------------------------------
# 🛡 Guard: Ensure valid Hugo site and content directory
# ---------------------------------------------------------

if ! has_hugo_config "$BLOG_ROOT"; then
  echo "❌ Not a valid Hugo site: no config.{toml,yaml} or hugo.toml found in $BLOG_ROOT"
  return 1 2>/dev/null || exit 1
fi

if [[ ! -d "$CONTENT_DIR" ]]; then
  echo "❌ Content directory not found: $CONTENT_DIR"
  return 1 2>/dev/null || exit 1
fi
