#!/bin/bash

# ------------------------------
# 📁 Project paths and structure
# ------------------------------

# Root directory of Hugo site
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUGO_SITE_DIR="${HUGO_SITE_DIR:-$SCRIPT_DIR/../../site}"

# Where content posts live
CONTENT_DIR="$HUGO_SITE_DIR/content/posts"

# Hugo config file (optional future use)
HUGO_CONFIG="$HUGO_SITE_DIR/hugo.toml"

# ------------------------------
# 🔗 GitHub configuration
# ------------------------------

# GitHub repo used for pushing changes
GITHUB_REPO="git@github.com:pwm-teach/morton-teaches.git"

# ------------------------------
# ⚙️ Script behaviour settings
# ------------------------------

# How many recent files to show in menus
MAX_RECENT=20

# Month that marks the start of a new academic year (e.g. 7 = July)
ACADEMIC_YEAR_START_MONTH=7

# Format for academic year subfolders (e.g. 2024-2025)
ACADEMIC_YEAR_FORMAT="%Y-%Y"
