#!/usr/bin/env bash

# ---------------------------------------------------------
# 🗑️ Hugo delete post script
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

# ---------------------------------------------------------
# 🚀 Load recent posts and display menu
# ---------------------------------------------------------

echo "🗂️  Available posts for deletion (most recent first):"
recent_files=()
load_recent_posts 20 recent_files

echo ""
display_menu_items "${recent_files[@]}"
echo ""
echo "📝 Enter post numbers to delete (e.g. 1 3 5 or 2-4, or combinations):"
read -r input

# Expand ranges like 2-4 into 2 3 4
expanded=()
for token in $input; do
  if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
    IFS='-' read -r start end <<< "$token"
    for ((i=start; i<=end; i++)); do
      expanded+=("$i")
    done
  elif [[ "$token" =~ ^[0-9]+$ ]]; then
    expanded+=("$token")
  fi
done

# Validate selections
to_delete=()
for num in "${expanded[@]}"; do
  if [[ "$num" -ge 1 && "$num" -le ${#recent_files[@]} ]]; then
    to_delete+=("${recent_files[$((num - 1))]}")
  else
    echo "⚠️  Skipping invalid selection: $num"
  fi
done

if [[ ${#to_delete[@]} -eq 0 ]]; then
  fatal "No valid posts selected for deletion."
fi

# Confirm each file before deletion
confirmed=()
for file in "${to_delete[@]}"; do
  echo -n "❓ Confirm deletion of $(basename "$file")? [y/N] "
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    confirmed+=("$file")
  fi
done

if [[ ${#confirmed[@]} -eq 0 ]]; then
  echo "❌ No posts confirmed for deletion."
  exit 0
fi

# Delete confirmed files
echo ""
echo "🧹 Deleting ${#confirmed[@]} post(s)..."
for file in "${confirmed[@]}"; do
  rm -f "$file"
  echo "🗑️  Deleted: $(basename "$file")"
done

# Offer to commit
echo ""
echo "🚀 Commit and push deletions? [y/N]"
read -r push_confirm
if [[ "$push_confirm" =~ ^[Yy]$ ]]; then
  "$LIB_DIR/git-autocommit.sh" -m "🗑️ Deleted ${#confirmed[@]} post(s)" "${confirmed[@]}"
  echo "✅ Changes committed and pushed."
else
  echo "💡 You can commit manually later:"
  for f in "${confirmed[@]}"; do
    echo "   git rm \"$f\""
  done
  echo "   git commit -m 'Deleted post(s)' && git push"
fi
