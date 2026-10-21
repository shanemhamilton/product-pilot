#!/bin/sh
# Shared helpers for the Product Pilot scripts. Source it; do not run it.
# Resolves the repo root and the Pilot path, and exposes small parsers.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT" || exit 2

pilot_path() {
  if [ -n "${PILOT_PATH:-}" ]; then printf '%s\n' "$PILOT_PATH"; return; fi
  for c in docs/product/PRODUCT_PILOT.md docs/PRODUCT_PILOT.md documentation/product/PRODUCT_PILOT.md PRODUCT_PILOT.md; do
    [ -f "$c" ] && { printf '%s\n' "$c"; return; }
  done
  git ls-files 2>/dev/null | grep -m1 '/PRODUCT_PILOT\.md$\|^PRODUCT_PILOT\.md$'
}

PILOT=$(pilot_path)
PRODUCT_DOCS=$(dirname "${PILOT:-docs/product/x}")
TODAY=$(date +%Y-%m-%d)
WARN_DIVERGENCE=10   # commits behind HEAD before a warning
BLOCK_DIVERGENCE=20  # commits behind HEAD before pre-commit blocks

pilot_header() { # $1 = header label, e.g. "Last commit captured"
  grep -m1 -oE "$1: [^ >-]+" "$PILOT" | awk '{print $NF}'
}

pilot_format_version() { grep -m1 -oE 'format version: [0-9.]+' "$PILOT" | awk '{print $3}'; }

# True when the Pilot is tracked and identical to origin/main. An untracked file is not reviewed.
pilot_is_reviewed() {
  git rev-parse -q --verify origin/main >/dev/null 2>&1 &&
    git ls-files --error-unmatch "$PILOT" >/dev/null 2>&1 &&
    git diff --quiet origin/main -- "$PILOT" 2>/dev/null
}

pilot_divergence() { # commits between the anchor and HEAD
  a=$(pilot_header "Last commit captured")
  if [ -n "$a" ] && git cat-file -e "$a" 2>/dev/null; then git rev-list --count "$a..HEAD" 2>/dev/null || echo 0; else echo 0; fi
}

# Print the ACTIVE milestone block: from the "← ACTIVE" line to the next milestone, heading, or rule.
pilot_active_block() {
  awk '/^(- |#).*(← ACTIVE|<- ACTIVE)[[:space:]]*$/{p=1; print; next} p && /^(- |#|---)/{exit} p{print}' "$PILOT"
}

# Runway: open tasks under ACTIVE, and pourable tasks anywhere under Active Milestones.
pilot_runway() {
  open=$(pilot_active_block | grep -cE '^[[:space:]]*- \[ \] ' || true)
  pourable=$(awk '/^## Active Milestones/{p=1} /^## Decision Pending/{p=0} p' "$PILOT" | grep -cE '^[[:space:]]*- \[ \] \[unpoured\]' || true)
  printf 'open_active=%s pourable=%s\n' "$open" "$pourable"
}

# Decision rows past their deadline for a given tier ($1), from the 7-column table.
pilot_decisions_due() {
  awk -v tier="$1" -v today="$TODAY" '
    /^## Decision Pending/{p=1; next} /^## /{p=0}
    p && /^\|/ && $0 !~ /^\| *ID *\|/ && $0 !~ /^\|[- |]+\|$/ {
      n=split($0, c, "|"); if (n < 8) next
      gsub(/^ +| +$/, "", c[2]); gsub(/^ +| +$/, "", c[4]); gsub(/^ +| +$/, "", c[5]); gsub(/^ +| +$/, "", c[6])
      if (c[4] == tier && c[6] != "" && c[6] <= today) printf "%s | %s | default: %s | deadline: %s\n", c[2], c[3], c[5], c[6]
    }' "$PILOT"
}
