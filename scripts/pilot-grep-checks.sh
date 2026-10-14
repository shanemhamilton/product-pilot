#!/bin/sh
# Deterministic structure checks for a filled PRODUCT_PILOT.md.
# Generalized from the myskiniq tenant's scripts/pilot-grep-checks.sh (2026-10).
#
#   --banner      SessionStart display. Always exits 0.
#   --pre-commit  Exit 1 on a structural FAIL, or when the anchor is more than
#                 20 commits behind HEAD and this commit does not touch the Pilot.
#   --ci          Exit 1 on a structural FAIL. Divergence is a warning only.
#
# Override the Pilot location with PILOT_PATH=path/to/PRODUCT_PILOT.md.
set -u
. "$(dirname "$0")/pilot-lib.sh"
MODE="${1:---banner}"
[ -f "${PILOT:-}" ] || { echo "no PRODUCT_PILOT.md found"; exit 0; }

WARN_DIVERGENCE=10
BLOCK_DIVERGENCE=20
FAILS=0; DETAIL=""; WARNS=""
fail() { FAILS=$((FAILS + 1)); DETAIL="${DETAIL}  FAIL: $1
"; }
warn() { WARNS="${WARNS}  WARN: $1
"; }

# 1. Product docs directory must be version-controlled.
git check-ignore -q "$PRODUCT_DOCS" 2>/dev/null && fail "$PRODUCT_DOCS is gitignored; the Pilot is not tracked"

# 2. No unfilled placeholders in the product docs.
grep -rq "\[PLACEHOLDER:" "$PRODUCT_DOCS" 2>/dev/null && fail "unfilled [PLACEHOLDER:] markers survive in $PRODUCT_DOCS"

# 3. Exactly one ACTIVE marker.
ACTIVE_COUNT=$(grep -cE "(← ACTIVE|<- ACTIVE)[[:space:]]*$" "$PILOT" || true)
[ "$ACTIVE_COUNT" = "1" ] || fail "$ACTIVE_COUNT applied ACTIVE markers (expected 1)"

# 4. Anchor references a real commit.
LAST_HASH=$(pilot_header "Last commit captured")
if [ -z "$LAST_HASH" ]; then fail "missing 'Last commit captured: <sha>' header"
elif ! git cat-file -e "$LAST_HASH" 2>/dev/null; then fail "Last commit captured references unknown commit $LAST_HASH"; fi

# 5. Required sections.
for S in "## Quick Orientation" "## Agent Operating Instructions" "## Active Milestones" "## Decision Pending" \
         "## Recent Shipped" "## Phase Transitions" "## Metrics Snapshot" "## Open Tooling Gaps" "## Changelog"; do
  grep -qF "$S" "$PILOT" || fail "missing section: $S"
done
SCOPE=$(pilot_header "Pilot scope")
case "$SCOPE" in Full|Lite) grep -qF "## Product Docs Index" "$PILOT" || fail "scope $SCOPE requires ## Product Docs Index";; esac

# 6. Length.
LINES=$(wc -l < "$PILOT" | tr -d ' ')
[ "$LINES" -le 140 ] || fail "$LINES lines (target 140 or fewer)"

# 7. Format 3.0: every open task carries a ticket tag or [unpoured].
FMT=$(pilot_format_version)
UNTAGGED=$(awk '/^## Active Milestones/{p=1} /^## Decision Pending/{p=0} p' "$PILOT" | grep -cE '^[[:space:]]*- \[[ x]\] [^[]' || true)
if [ "$UNTAGGED" != "0" ]; then
  case "$FMT" in 3*) fail "$UNTAGGED task(s) without a [TICKET] or [unpoured] tag";; *) warn "$UNTAGGED task(s) without a [TICKET] tag (format $FMT; required from 3.0)";; esac
fi

DIVERGENCE=$(pilot_divergence)
HEAD_SHORT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)

case "$MODE" in
  --banner)
    echo "=== PILOT CHECK ($PILOT) ==="
    if [ "$FAILS" -eq 0 ]; then echo "ok: $LINES lines, 1 ACTIVE, no placeholders, anchor $LAST_HASH"; else printf '%s defect(s):\n%s' "$FAILS" "$DETAIL"; fi
    printf '%s' "$WARNS"
    [ "$DIVERGENCE" -gt "$WARN_DIVERGENCE" ] && echo "WARN: anchor $LAST_HASH is $DIVERGENCE commits behind HEAD $HEAD_SHORT; run scripts/pilot-reconcile.sh"
    exit 0 ;;
  --pre-commit)
    if [ "$FAILS" -gt 0 ]; then printf 'Pilot check: %s defect(s) in %s\n%s' "$FAILS" "$PILOT" "$DETAIL" >&2; exit 1; fi
    if [ "$DIVERGENCE" -gt "$BLOCK_DIVERGENCE" ] && ! git diff --cached --name-only | grep -qx "$PILOT"; then
      echo "Pilot check: anchor $LAST_HASH is $DIVERGENCE commits behind HEAD; run scripts/pilot-reconcile.sh --apply and stage $PILOT" >&2; exit 1
    fi
    exit 0 ;;
  --ci)
    if [ "$FAILS" -gt 0 ]; then printf 'Pilot check: %s defect(s) in %s\n%s' "$FAILS" "$PILOT" "$DETAIL" >&2; exit 1; fi
    printf '%s' "$WARNS"
    [ "$DIVERGENCE" -gt "$WARN_DIVERGENCE" ] && echo "WARN: anchor $DIVERGENCE commits behind HEAD"
    exit 0 ;;
  *) echo "usage: $0 [--banner|--pre-commit|--ci]" >&2; exit 2 ;;
esac
