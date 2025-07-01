#!/usr/bin/env bash

# ---------------------------------------------------------
# 🗑️ Hugo post deletion script (interactive)
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
CONTENT_DIR="$SCRIPT_DIR/../../content/posts"

# Load shared utils
if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  echo "❌ Could not load utils from $LIB_DIR/utils.sh"
  exit 1
fi

# Load Hugo env
if ! source "$LIB_DIR/hugo.sh" || [[ -z "$HUGO_ENV_OK" ]]; then
  fatal "Could not load Hugo environment"
fi

# Load metadata helpers
if [[ -f "$LIB_DIR/metadata.sh" ]]; then
  source "$LIB_DIR/metadata.sh"
else
  fatal "Could not load metadata.sh"
fi

# Load git auto-commit
GIT_HELPER="$LIB_DIR/git-autocommit.sh"

# ---------------------------------------------------------
# 🧠 Helpers
# ---------------------------------------------------------

list_all_posts() {
  find "$CONTENT_DIR" -name "*.md" ! -name "_index.md" -print0 | while IFS= read -r -d '' file; do
    if [[ "$(uname)" == "Darwin" ]]; then
      echo "$(stat -f '%m' "$file") $file"
    else
      echo "$(stat --format='%Y' "$file") $file"
    fi
  done | sort -rn | cut -d' ' -f2-
}

display_post_menu() {
  local -a files=("$@")
  local i=1
  for file in "${files[@]}"; do
    local title
    title=$(extract_title "$file")
    printf "  %2d) %s [%s]\n" "$i" "$title" "$(basename "$file")"
    ((i++))
  done
}

parse_selection() {
  local input="$1"
  local total="$2"
  local selected=()

  input=$(echo "$input" | tr ',' ' ')

  for part in $input; do
    if [[ $part =~ ^[0-9]+$ ]]; then
      selected+=("$part")
    elif [[ $part =~ ^([0-9]+)-([0-9]+)$ ]]; then
      for ((i=${BASH_REMATCH[1]}; i<=${BASH_REMATCH[2]}; i++)); do
        selected+=("$i")
      done
    fi
  done

  echo "${selected[@]}" | tr ' ' '\n' | sort -nu | awk -v max="$total" '$1 >= 1 && $1 <= max'
}

# ---------------------------------------------------------
# 🚀 Main
# ---------------------------------------------------------

echo "🗂️  Available posts for deletion (most recent first):"
echo ""

POSTS=()
while IFS= read -r line; do
  POSTS+=("$line")
done < <(list_all_posts)

TOTAL=${#POSTS[@]}

if [[ $TOTAL -eq 0 ]]; then
  echo "🚫 No posts found."
  exit 0
fi

display_post_menu "${POSTS[@]}"
echo ""
echo "📝 Enter post numbers to delete (e.g. 1 3 5 or 2-4, or combinations):"
read -r input

SELECTION=()
while IFS= read -r line; do
  SELECTION+=("$line")
done < <(parse_selection "$input" "$TOTAL")

if [[ ${#SELECTION[@]} -eq 0 ]]; then
  echo "⚠️  No valid selections."
  exit 1
fi

FILES_TO_DELETE=()
for i in "${SELECTION[@]}"; do
  file="${POSTS[$((i - 1))]}"
  echo -n "❓ Confirm deletion of $(basename "$file")? [y/N] "
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    FILES_TO_DELETE+=("$file")
  fi
done

if [[ ${#FILES_TO_DELETE[@]} -eq 0 ]]; then
  echo "❌ No files deleted."
  exit 0
fi

echo ""
echo "🧹 Deleting ${#FILES_TO_DELETE[@]} post(s)..."
for file in "${FILES_TO_DELETE[@]}"; do
  rm -f "$file"
  echo "🗑️  Deleted: $(basename "$file")"
done

# ---------------------------------------------------------
# 💬 Git auto-commit
# ---------------------------------------------------------

echo ""
echo "🚀 Commit and push deletions? [y/N]"
read -r confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  if [[ -x "$GIT_HELPER" ]]; then
    COMMIT_MSG="🗑️ Deleted ${#FILES_TO_DELETE[@]} post(s)"
    "$GIT_HELPER" "${FILES_TO_DELETE[@]}" -m "$COMMIT_MSG"
    echo "✅ Changes committed and pushed."
  else
    echo "⚠️  git-autocommit.sh not found or not executable at: $GIT_HELPER"
  fi
else
  echo "💡 You can commit manually later with:"
  for f in "${FILES_TO_DELETE[@]}"; do
    echo "   git rm \"$f\""
  done
fi
