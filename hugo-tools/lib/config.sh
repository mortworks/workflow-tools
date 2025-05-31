#!/bin/bash

# ---------------------------------------------------------
# 🌱 Configure Hugo blog environment
# ---------------------------------------------------------

# Detect the current working repo (e.g., /workspaces/teach-blog)
BLOG_ROOT="$(git rev-parse --show-toplevel)"

# Optionally override from .blogrc if present
if [[ -f "$BLOG_ROOT/.blogrc" ]]; then
  source "$BLOG_ROOT/.blogrc"
fi

# Fallbacks if .blogrc didn't set them
CONTENT_DIR="${CONTENT_DIR:-$BLOG_ROOT/content/posts}"
DRAFT_DIR="${DRAFT_DIR:-$BLOG_ROOT/_drafts}"
