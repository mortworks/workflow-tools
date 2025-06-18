#!/usr/bin/env bash

# ---------------------------------------------------------
# 🌱 Configure Hugo blog environment
# ---------------------------------------------------------

# Resolve the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utils if not already available
if ! declare -F fatal >/dev/null 2>&1; then
  if [[ -f "$SCRIPT_DIR/utils.sh" ]]; then
    source "$SCRIPT_DIR/utils.sh"
  else
    echo "❌ [ERROR] Could not find utils.sh in $SCRIPT_DIR"
    return 1 2>/dev/null || exit 1
  fi
fi

# Locate Hugo root by walking up the directory tree
find_hugo_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/hugo.toml" || -f "$dir/config.toml" || -f "$dir/config.yaml" || -f "$dir/hugo.yaml" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Attempt to locate BLOG_ROOT
BLOG_ROOT="$(find_hugo_root 2>/dev/null)"
if [[ -z "$BLOG_ROOT" ]]; then
  fatal "Could not locate a Hugo site (no config file found)."
fi

# Confirm valid config file still exists
if [[ ! -f "$BLOG_ROOT/hugo.toml" && ! -f "$BLOG_ROOT/config.toml" && ! -f "$BLOG_ROOT/config.yaml" && ! -f "$BLOG_ROOT/hugo.yaml" ]]; then
  fatal "Not a valid Hugo site: no config file found at $BLOG_ROOT"
fi

# Load optional overrides
if [[ -f "$BLOG_ROOT/.blogrc" ]]; then
  source "$BLOG_ROOT/.blogrc"
fi

# Define default content paths
CONTENT_DIR="${CONTENT_DIR:-$BLOG_ROOT/content/posts}"
DRAFT_DIR="${DRAFT_DIR:-$BLOG_ROOT/_drafts}"

# Check for content directory
if [[ ! -d "$CONTENT_DIR" ]]; then
  fatal "Content directory does not exist: $CONTENT_DIR"
fi

# ✅ Signal successful environment load
HUGO_ENV_OK=true
