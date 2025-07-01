#!/usr/bin/env bash

# ---------------------------------------------------------
# 🗑️ Hugo post deletion script
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Load shared utils and fatal()
if [[ -f "$LIB_DIR/utils.sh" ]]; then
  source "$LIB_DIR/utils.sh"
else
  echo "❌ [ERROR] Could not load utilities from $LIB_DIR/utils.sh"
  exit 1
fi

# Load Hugo environment
if ! source "$LIB_DIR/hugo.sh" || [[ -z "$HUGO_ENV_OK" ]]; then
  fatal "Aborting: could not load Hugo environment."
fi

# Load shared metadata functions
if [[ -f "$LIB_DIR/metadata.sh" ]]; then
  source "$LIB_DIR/metadata.sh"
else
  fatal "Aborting: metadata.sh not found in $LIB_DIR"
fi

# ---------------------------------------------------------
# 🚀 Main logic
# ---------------------------------------------------------

echo "🗂️  Available posts for deletion (most recent first):"
load_recent_posts 20 files

if [[ ${#files[@]} -eq 0 ]]; then
  echo "🚫 No posts found."
  exit 0
fi

echo ""
display_menu_items "${files[@]}"
echo ""
echo "📝 Enter post numbers to delete (e.g. 1 3 5 or 2-4, or combinations):"
read -r selection

# Expand ranges like 2-4 into 2 3 4
expanded=()
for part in $selection; do
  if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    for ((i=${BASH_REMATCH[1]}; i<=${BASH_REMATCH[2]}; i++)); do
      expanded+=("$i")
    done
  elif [[ "$part" =~ ^[0-9]+$ ]]; then
    expanded+=("$part")
  fi
done

# Validate and collect confirmed deletions
to_delete=()
for index in "${expanded[@]}"; do
  if [[ "$index" -ge 1 && "$index" -le ${#files[@]} ]]; then
    file="${files[$((index - 1))]}"
    filename="$(basename "$file")"
    echo -n "❓ Confirm deletion of $filename? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      to_delete+=("$file")
    fi
  fi
done

if [[ ${#to_delete[@]} -eq 0 ]]; then
  echo "❌ No files confirmed for deletion."
  exit 0
fi

# Delete and commit
echo ""
echo "🧹 Deleting ${#to_delete[@]} post(s)..."
for file in "${to_delete[@]}"; do
  rm -f "$file" && echo "🗑️  Deleted: $(basename "$file")"
done

echo ""
echo "🚀 Commit and push deletions? [y/N]"
read -r do_commit
if [[ "$do_commit" =~ ^[Yy]$ ]]; then
  GIT_HELPER="$LIB_DIR/git-autocommit.sh"
  message="🗑️ Deleted ${#to_delete[@]} post(s)"
  if [[ -x "$GIT_HELPER" ]]; then
    "$GIT_HELPER" "${to_delete[@]}" --message "$message"
  else
    echo "⚠️  git-autocommit.sh not found or not executable at: $GIT_HELPER"
  fi
else
  echo "💡 Remember to commit manually:"
  printf '   git rm "%s"\n' "${to_delete[@]}"
  echo "   git commit -m \"Deleted posts\" && git push"
fi
