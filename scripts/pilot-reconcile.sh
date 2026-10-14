#!/bin/sh
# Evidence-driven Pilot maintenance. Dry run by default; --apply writes.
#
#   1. Regenerates "Recent Shipped" from git log (paths from the "Shipped paths" comment).
#   2. Runs the ACTIVE milestone's Check and the next Phase Transition Check.
#   3. Advances "← ACTIVE" when the Check passes and every ACTIVE task is ticked (--apply).
#   4. Reports decisions past their Deadline and the runway.
#   5. Updates "Last commit captured" and "Last updated" (--apply).
#
# Checks are shell commands written in the Pilot by its Owner. Because anyone who can
# land a Pilot edit could plant one, they run only with --run-checks, and only when the
# Pilot is identical to origin/main (the reviewed state) unless --trust-local is given.
# Each command is printed before it runs. Ticking tasks is left to the agent: a task is
# done when its ticket is closed, and this script does not know the tracker.
# Usage: pilot-reconcile.sh [--apply] [--run-checks] [--trust-local] [--since YYYY-MM-DD]
set -u
trap "" PIPE  # a consumer that stops reading early (head, grep -q) must not abort the write step
. "$(dirname "$0")/pilot-lib.sh"
[ -f "${PILOT:-}" ] || { echo "no PRODUCT_PILOT.md found"; exit 0; }
APPLY=0; SINCE=""; RUN=0; TRUST=0
while [ $# -gt 0 ]; do case "$1" in --apply) APPLY=1;; --run-checks) RUN=1;; --trust-local) TRUST=1;; --since) SINCE="$2"; shift;; *) echo "usage: $0 [--apply] [--run-checks] [--trust-local] [--since DATE]" >&2; exit 2;; esac; shift; done
TIMEOUT=""; command -v timeout >/dev/null 2>&1 && TIMEOUT="timeout 120"; command -v gtimeout >/dev/null 2>&1 && TIMEOUT="gtimeout 120"
CHECKS_OK=0
if [ "$RUN" = 1 ]; then
  if [ "$TRUST" = 1 ]; then CHECKS_OK=1
  elif ! git rev-parse -q --verify origin/main >/dev/null 2>&1; then echo "checks skipped: no origin/main to compare against (pass --trust-local to run anyway)"
  elif ! git diff --quiet origin/main -- 2>/dev/null || [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "checks skipped: the working tree differs from origin/main (a Check may call any file in it); merge first or pass --trust-local"
  else CHECKS_OK=1; fi
fi
run_check() { # $1 = command; prints PASS/FAIL/skipped and returns its status
  [ -z "$1" ] && { echo "none"; return 2; }
  case "$1" in manual*) echo "manual"; return 2;; esac
  [ "$CHECKS_OK" = 1 ] || { echo "skipped"; return 2; }
  echo "running: $1" >&2
  if $TIMEOUT sh -c "$1" >/dev/null 2>&1; then echo PASS; return 0; else echo FAIL; return 1; fi
}
# The anchor must survive a squash merge, so it is the merge base with origin/main when one exists.
ANCHOR_REF=$(git merge-base HEAD origin/main 2>/dev/null || git rev-parse HEAD)
HEAD_SHORT=$(git rev-parse --short "$ANCHOR_REF")
TD=$(mktemp -d) || exit 2; trap 'rm -rf "$TD"' EXIT  # private scratch dir; no predictable names
TMP="$TD/pilot"; cp "$PILOT" "$TMP"

# 1. Recent Shipped
[ -z "$SINCE" ] && SINCE=$(grep -m1 -oE '## Recent Shipped \(since [0-9-]+\)' "$PILOT" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
PATHS=$(grep -m1 -oE 'Shipped paths: [^>]+' "$PILOT" | sed 's/Shipped paths: //; s/ *--$//; s/ *$//'); PATHS=${PATHS:-.}
# shellcheck disable=SC2086
SHIPPED=$(git log --no-merges --since="${SINCE:-1970-01-01} 00:00" --format='- %h %s' -- $PATHS | head -15)
COUNT=$(printf '%s' "$SHIPPED" | grep -c . || true)
echo "recent shipped: $COUNT commit(s) since ${SINCE:-beginning} in [$PATHS]"
if [ "$APPLY" = 1 ]; then
  printf '%s\n' "$SHIPPED" > "$TD/ship"
  awk -v f="$TD/ship" -v since="$SINCE" '
    /^## Recent Shipped/ { print "## Recent Shipped (since " since ")"; print ""; p=1; next }
    p && /^<!--/ { print; next }
    p && /^(---|## )/ { print ""; while ((getline l < f) > 0) print l; print ""; print; p=0; next }
    p { next }
    { print }' "$TMP" > "$TD/new" && mv "$TD/new" "$TMP"
fi

# 2. ACTIVE milestone check
ACTIVE_LINE=$(grep -m1 -E '(← ACTIVE|<- ACTIVE)[[:space:]]*$' "$PILOT")
ACTIVE_ID=$(printf '%s' "$ACTIVE_LINE" | grep -oE '\[[^]]+\]' | head -1)
[ -z "$ACTIVE_ID" ] && ACTIVE_ID=$(printf '%s' "$ACTIVE_LINE" | sed -E 's/^[-# ]*//; s/\*\*//g; s/[[:space:]]*(← ACTIVE|<- ACTIVE).*$//' | cut -c1-60)
CHECK=$(pilot_active_block | grep -m1 -E '^[[:space:]]*- Check:' | sed -n 's/.*`\(.*\)`.*/\1/p')
OPEN=$(pilot_active_block | grep -cE '^[[:space:]]*- \[ \] ' || true)
RESULT=$(run_check "$CHECK"); RC=$?
echo "active $ACTIVE_ID: check=$RESULT open_tasks=$OPEN"
NEXT_ID=$(awk '/(← ACTIVE|<- ACTIVE)[[:space:]]*$/{p=1; next} p && /^- \*\*\[/{print; exit}' "$PILOT" | grep -oE '\[[^]]+\]' | head -1)
if [ "$RC" = 0 ] && [ "$OPEN" = 0 ]; then
  if [ -z "$NEXT_ID" ]; then echo "ADVANCE: $ACTIVE_ID complete and no next milestone; the Owner must plan the next phase"
  elif [ "$APPLY" = 1 ]; then
    awk -v nid="$NEXT_ID" -v today="$TODAY" -v aid="$ACTIVE_ID" '
      /(← ACTIVE|<- ACTIVE)[[:space:]]*$/ && !done1 { sub(/[[:space:]]*(← ACTIVE|<- ACTIVE)[[:space:]]*$/, ""); print; done1=1; next }
      done1 && !done2 && index($0, "- **" nid) == 1 { print $0 " ← ACTIVE"; done2=1; next }
      /^## Changelog/ { print; inlog=1; next }
      inlog && /^- / && !logged { print "- " today " — Advanced ← ACTIVE from " aid " to " nid " (Check passed)"; logged=1 }
      { print }' "$TMP" > "$TD/new" && mv "$TD/new" "$TMP"
    echo "ADVANCE: moved ← ACTIVE from $ACTIVE_ID to $NEXT_ID"
  else echo "ADVANCE READY: $ACTIVE_ID -> $NEXT_ID (run with --apply)"; fi
elif [ "$RC" = 0 ]; then echo "ADVANCE BLOCKED: Check passed but $OPEN task(s) unticked; tick tasks whose tickets are closed"; fi

# 3. Phase transition check
TROW=$(awk '/^## Phase Transitions/{p=1; next} p && /^## /{exit} p && /^\|/ && $0 !~ /^\| *Transition/ && $0 !~ /^\|[- |]+\|$/' "$PILOT" | head -1)
TCHECK=$(printf '%s' "$TROW" | sed -n 's/.*`\(.*\)`.*/\1/p')
TNAME=$(printf '%s' "$TROW" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')
[ -n "$TROW" ] && echo "phase transition [$TNAME]: check=$(run_check "$TCHECK")"

# 4. Decisions and runway
due=$(pilot_decisions_due agent); [ -n "$due" ] && printf 'DECISION DUE (apply Default, log in ROADMAP.md):\n%s\n' "$due"
hd=$(pilot_decisions_due human); [ -n "$hd" ] && printf 'HUMAN DECISION OVERDUE (does not block the queue):\n%s\n' "$hd"
echo "runway: $(pilot_runway)"

# 5. Anchor and date
if [ "$APPLY" = 1 ]; then
  sed -e "s/Last commit captured: [^ >-]*/Last commit captured: $HEAD_SHORT/" -e "s/Last updated: [0-9-]*/Last updated: $TODAY/" "$TMP" > "$TD/new" && mv "$TD/new" "$TMP"
  cp "$TMP" "$PILOT"; echo "applied: anchor=$HEAD_SHORT updated=$TODAY ($PILOT)"
else echo "dry run: no changes written (use --apply; add --run-checks to execute Checks)"; fi
