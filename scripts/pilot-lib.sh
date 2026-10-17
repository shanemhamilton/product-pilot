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

pilot_header() { # $1 = header label, e.g. "Last commit captured"
  grep -m1 -oE "$1: [^ >-]+" "$PILOT" | awk '{print $NF}'
}

pilot_format_version() { grep -m1 -oE 'format version: [0-9.]+' "$PILOT" | awk '{print $3}'; }

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

# Execution evidence in the form pilot-grep-checks.sh accepts, extracted from free text such as a
# close reason or a comment: a commit SHA (backticked), then "build #N", then a CI run URL.
pilot_evidence() {
  for w in $(printf '%s' "$1" | grep -oE '(^|[^0-9A-Za-z])[0-9a-f]{7,40}([^0-9A-Za-z]|$)' | tr -cd '0-9a-f\n'); do
    case "$w" in *[a-f]*) case "$w" in *[0-9]*) printf '`%s`\n' "$w"; return;; esac;; esac
  done
  e=$(printf '%s' "$1" | grep -oE '(^|[^A-Za-z])(build|builds|BK|Buildkite|run) #?[0-9]+' | head -1)
  [ -n "$e" ] && { printf 'build #%s\n' "${e##*[!0-9]}"; return; }
  printf '%s' "$1" | grep -oE 'https?://[^ )]+/(builds|actions/runs)/[0-9]+' | head -1
}

# Minimal JSON without jq. json_str: stdin as a JSON string body (no quotes). json_field: the
# first "name": "value" in stdin; a value holding an escaped quote is cut at that quote.
json_str() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\t' ' ' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//'; }
json_field() { grep -oE "\"$1\": *\"[^\"]*\"" | head -1 | sed 's/^[^:]*: *"//; s/"$//'; }

# Linear GraphQL. $1 = document with no user text in it, $2 = variables as a JSON object.
# Prints the response; an API error goes to stderr and the response still prints.
linear_gql() {
  v=${2:-"{}"}; k=$(mktemp -d) || return 1  # the key travels in a 0700 scratch dir, never in argv
  printf 'header = "Authorization: %s"\n' "${LINEAR_API_KEY:-}" > "$k/auth"
  r=$(printf '{"query":"%s","variables":%s}' "$(printf '%s\n' "$1" | json_str)" "$v" | curl -sS --max-time 30 \
    -K "$k/auth" -H 'Content-Type: application/json' --data-binary @- https://api.linear.app/graphql 2>/dev/null)
  rm -f "$k/auth"; rmdir "$k"
  case "$r" in *'"errors"'*) echo "linear: $(printf '%s' "$r" | json_field message)" >&2;; esac
  printf '%s\n' "$r"
}
