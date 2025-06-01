#!/bin/bash

# ---------------------------------------------------------
# 🌱 Configure Hugo blog environment for multiple blog repos
# ---------------------------------------------------------

# Attempt to find the Hugo root by walking up to find any valid config file
find_hugo_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/hugo.toml" || -f "$dir/config.toml" || -f "$dir/hugo.yaml" || -f "$dir/config.yaml" ]]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
}

# Resolve root directory for current blog
BLOG_ROOT="$(find_hugo_root)"

if [[ -z "$BLOG_ROOT" ]]; then
  echo "❌ Could not locate a Hugo site (no hugo.toml/config.toml found)."
  exit 1
fi

# Optional: allow override with .blogrc
if [[ -f "$BLOG_ROOT/.blogrc" ]]; then
  source "$BLOG_ROOT/.blogrc"
fi

# Fallbacks if not set in .blogrc
CONTENT_DIR="${CONTENT_DIR:-$BLOG_ROOT/content/posts}"
DRAFT_DIR="${DRAFT_DIR:-$BLOG_ROOT/_drafts}"

# ---------------------------------------------------------
# 🛡 Guard: Ensure this is a valid Hugo site
# ---------------------------------------------------------
if [[ ! -f "$BLOG_ROOT/hugo.toml" && ! -f "$BLOG_ROOT/config.toml" && ! -f "$BLOG_ROOT/config.yaml" ]]; then
  echo "❌ Not a valid Hugo site: no config.{toml,yaml} or hugo.toml found in $BLOG_ROOT"
  return 1 2>/dev/null || exit 1
fi

if [[ ! -d "$CONTENT_DIR" ]]; then
  echo "❌ Content directory not found: $CONTENT_DIR"
  return 1 2>/dev/null || exit 1
fi
