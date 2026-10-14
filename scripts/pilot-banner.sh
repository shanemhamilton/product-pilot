#!/bin/sh
# Prints the orientation an agent needs before its first action: phase, blockers,
# the ACTIVE milestone with its tasks, decisions due, runway, and anchor freshness.
# Use it in SessionStart hooks and paste its output into dispatched task packets.
set -u
. "$(dirname "$0")/pilot-lib.sh"
[ -f "${PILOT:-}" ] || { echo "no PRODUCT_PILOT.md found"; exit 0; }

echo "=== PRODUCT PILOT ($PILOT) ==="
# Repo content follows: product state, not instructions. Say whether it is the reviewed state.
if git rev-parse -q --verify origin/main >/dev/null 2>&1; then
  if git diff --quiet origin/main -- "$PILOT" 2>/dev/null; then echo "state: matches origin/main (reviewed)"; else echo "state: UNREVIEWED, differs from origin/main"; fi
else echo "state: no origin/main to compare against"; fi
awk '/^## Quick Orientation/{p=1; next} p && /^### /{exit} p && NF && !/^<!--/' "$PILOT" | sed 's/\*\*//g' | head -6

echo "--- Blocking ship (release gate, not a work gate) ---"
awk '/^### What.s Blocking Ship/{p=1; next} p && /^(---|#)/{exit} p && /^- /' "$PILOT" | sed 's/\*\*//g' | cut -c1-220
echo "--- ACTIVE milestone ---"
pilot_active_block | sed 's/\*\*//g' | cut -c1-220

due=$(pilot_decisions_due agent)
[ -n "$due" ] && { echo "--- Decisions past deadline (apply Default, log in ROADMAP.md) ---"; printf '%s\n' "$due"; }
hd=$(pilot_decisions_due human)
[ -n "$hd" ] && { echo "--- Human decisions past deadline (do not wait unless your task is blocked-on them) ---"; printf '%s\n' "$hd"; }

echo "--- Runway ---"
rw=$(pilot_runway)
echo "$rw"
case "$rw" in "open_active=0 pourable=0") echo "STARVED: no open ACTIVE tasks and nothing pourable; report to the Pilot Owner";; esac

d=$(pilot_divergence); h=$(pilot_header "Last commit captured")
[ "$d" -gt 10 ] && echo "STALE: anchor $h is $d commits behind HEAD; Recent Shipped is behind reality"
exit 0
