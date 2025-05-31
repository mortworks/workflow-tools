#!/bin/bash

# Resolve through any symlinks to get the true script directory
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# Set blog root relative to the real script location
BLOG_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTENT_DIR="$BLOG_ROOT/site/content/posts"
