#!/bin/sh
# Evidence-driven Pilot maintenance. Dry run by default; --apply writes.
#
#   1. Regenerates "Recent Shipped" from git log (paths from the "Shipped paths" comment).
#   2. Ticks each open ACTIVE task whose ticket the tracker shows closed with execution evidence,
#      writing the evidence on the line: Beads ([prefix-id], close reason or last comment), GitHub
#      ([#N], [repo#N], [owner/repo#N]: a merged PR's merge commit, or the merge commit of the PR
#      that closed an issue), Linear ([KEY-N] with LINEAR_API_KEY: a completed issue's GitHub PR
#      attachment resolved through gh). A closed ticket without evidence is reported, not ticked.
#   3. Runs the ACTIVE milestone's Check and the next Phase Transition Check.
#   4. Advances "← ACTIVE" when the Check passes and every ACTIVE task is ticked (--apply),
#      counting the tasks ticked in this run.
#   5. Reports decisions past their Deadline and the runway.
#   6. Updates "Last commit captured" and "Last updated" (--apply).
#
# Checks are shell commands written in the Pilot by its Owner. Because anyone who can
# land a Pilot edit could plant one, they run only with --run-checks, and only when the
# Pilot is identical to origin/main (the reviewed state) unless --trust-local is given.
# Each command is printed before it runs.
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

# 2. Tick open ACTIVE tasks the tracker shows closed with evidence.
# Each resolver prints one of: "tick <evidence>", "closed" (no evidence), "open[ detail]", "unresolved (<why>)".
sha7() { printf '`%.7s`\n' "$1"; }
gh_merge_sha() { # $1 = owner/repo or "" for origin, $2 = number; prints the merge commit of a MERGED PR
  # shellcheck disable=SC2086
  gh pr view "$2" ${1:+--repo "$1"} --json state,mergeCommit --jq 'select(.state=="MERGED") | .mergeCommit.oid' 2>/dev/null
}
gh_repo_for() { # $1 = alias, $2 = number: a Pilot link to that number in a repo whose name contains the alias, else origin's owner
  r=$(grep -oiE "github\.com/[^/ ]+/[^/ ]*$1[^/ ]*/(pull|issues)/$2([^0-9]|$)" "$PILOT" | head -1 | sed -E 's#^github\.com/##; s#/(pull|issues)/[0-9]+.*$##')
  [ -n "$r" ] && { printf '%s\n' "$r"; return; }
  printf '%s/%s\n' "$(git remote get-url origin 2>/dev/null | sed -E 's#\.git$##; s#.*[:/]([^/:]+)/[^/]+$#\1#')" "$1"
}
resolve_gh() { # $1 = owner/repo or "", $2 = number
  sha=$(gh_merge_sha "$1" "$2"); [ -n "$sha" ] && { echo "tick $(sha7 "$sha")"; return; }
  # shellcheck disable=SC2086
  st=$(gh issue view "$2" ${1:+--repo "$1"} --json state,closedByPullRequestsReferences --jq '.state + " " + (.closedByPullRequestsReferences[0].url // "")' 2>/dev/null)
  case "$st" in
    "CLOSED https://github.com/"*/pull/*) u=${st#CLOSED https://github.com/}; sha=$(gh_merge_sha "${u%/pull/*}" "${u##*/}")
      if [ -n "$sha" ]; then echo "tick $(sha7 "$sha")"; else echo closed; fi;;
    OPEN*) echo open;; "") echo "unresolved (gh could not view ${1:-origin}#$2)";; *) echo closed;;
  esac
}
resolve_bd() { # $1 = bead id
  j=$(bd show "$1" --json 2>/dev/null) && [ -n "$j" ] || { echo "unresolved (bd show $1 failed)"; return; }
  [ "$(printf '%s' "$j" | json_field status)" = closed ] || { echo "open ($(printf '%s' "$j" | json_field status))"; return; }
  e=$(pilot_evidence "$(printf '%s' "$j" | json_field close_reason)")
  [ -n "$e" ] || e=$(pilot_evidence "$(bd comments "$1" --json 2>/dev/null | grep '"text":' | tail -1)")
  if [ -n "$e" ]; then echo "tick $e"; else echo closed; fi
}
resolve_linear() { # $1 = KEY-N; a completed issue with a GitHub PR attachment that gh shows merged
  r=$(linear_gql 'query($id: String!) { issue(id: $id) { state { type } attachments { nodes { url } } } }' "{\"id\":\"$1\"}")
  t=$(printf '%s' "$r" | json_field type)
  case "$t" in completed) ;; "") echo "unresolved (Linear returned no state for $1)"; return;; *) echo "open ($t)"; return;; esac
  for u in $(printf '%s' "$r" | grep -oE 'https://github\.com/[^"/]+/[^"/]+/pull/[0-9]+'); do
    p=${u#https://github.com/}; sha=$(gh_merge_sha "${p%/pull/*}" "${p##*/}"); [ -n "$sha" ] && { echo "tick $(sha7 "$sha")"; return; }
  done
  echo closed
}
resolve_tag() { # $1 = tag without brackets
  if printf '%s' "$1" | grep -q '#'; then
    command -v gh >/dev/null 2>&1 || { echo "unresolved (gh not on PATH)"; return; }
    n=${1##*#}; r=${1%#*}; case "$r" in ""|*/*) ;; *) r=$(gh_repo_for "$r" "$n");; esac; resolve_gh "$r" "$n"
  elif printf '%s' "$1" | grep -qE '^[A-Z][A-Z0-9]*-[0-9]+$'; then
    if [ -n "${LINEAR_API_KEY:-}" ]; then command -v gh >/dev/null 2>&1 && resolve_linear "$1" || echo "unresolved (gh not on PATH)"; else echo "unresolved (LINEAR_API_KEY not set)"; fi
  elif [ -d .beads ] && command -v bd >/dev/null 2>&1; then resolve_bd "$1"
  else echo "unresolved (no tracker for this tag)"; fi
}
tick_task() { # $1 = tag, $2 = evidence: tick the first open task carrying the tag under ACTIVE, in $TMP
  awk -v tag="[$1]" -v ev="$2" '
    /^(- |#).*(← ACTIVE|<- ACTIVE)[[:space:]]*$/ { a=1; print; next } a && /^(- |#|---)/ { a=0 }
    a && !done && index($0, "- [ ] " tag " ") { sub(/- \[ \] /, "- [x] "); $0 = $0 " at " ev; done=1 }
    { print }' "$TMP" > "$TD/new" && mv "$TD/new" "$TMP"
}
TICKED=0
while IFS= read -r line; do
  tag=$(printf '%s' "$line" | sed -nE 's/^[[:space:]]*- \[ \] \[([^]]+)\] .*/\1/p'); text=$(printf '%s' "$line" | sed -E 's/^[[:space:]]*- \[ \] \[[^]]+\] //')
  [ -n "$tag" ] && [ "$tag" != unpoured ] || continue
  res=$(resolve_tag "$tag" </dev/null)
  case "$res" in
    tick\ *) ev=${res#tick }; TICKED=$((TICKED + 1))
      if [ "$APPLY" = 1 ]; then tick_task "$tag" "$ev"; echo "ticked: [$tag] $ev"; else echo "would tick: [$tag] $ev"; fi;;
    closed) echo "CLOSED, no evidence: [$tag] $text";;
    open*) echo "open${res#open}: [$tag]";;
    *) echo "$res: [$tag]";;
  esac
done <<TASKS
$(pilot_active_block | grep -E '^[[:space:]]*- \[ \] ')
TASKS

# 3. ACTIVE milestone check
ACTIVE_LINE=$(grep -m1 -E '(← ACTIVE|<- ACTIVE)[[:space:]]*$' "$PILOT")
ACTIVE_ID=$(printf '%s' "$ACTIVE_LINE" | grep -oE '\[[^]]+\]' | head -1)
[ -z "$ACTIVE_ID" ] && ACTIVE_ID=$(printf '%s' "$ACTIVE_LINE" | sed -E 's/^[-# ]*//; s/\*\*//g; s/[[:space:]]*(← ACTIVE|<- ACTIVE).*$//' | cut -c1-60)
CHECK=$(pilot_active_block | grep -m1 -E '^[[:space:]]*- Check:' | sed -n 's/.*`\(.*\)`.*/\1/p')
OPEN=$(pilot_active_block | grep -cE '^[[:space:]]*- \[ \] ' || true); OPEN=$((OPEN - TICKED))
RESULT=$(run_check "$CHECK"); RC=$?
echo "active $ACTIVE_ID: check=$RESULT open_tasks=$OPEN ticked=$TICKED"
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
elif [ "$RC" = 0 ]; then echo "ADVANCE BLOCKED: Check passed but $OPEN task(s) unticked; see the open and CLOSED lines above"; fi

# 4. Phase transition check
TROW=$(awk '/^## Phase Transitions/{p=1; next} p && /^## /{exit} p && /^\|/ && $0 !~ /^\| *Transition/ && $0 !~ /^\|[- |]+\|$/' "$PILOT" | head -1)
TCHECK=$(printf '%s' "$TROW" | sed -n 's/.*`\(.*\)`.*/\1/p')
TNAME=$(printf '%s' "$TROW" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')
[ -n "$TROW" ] && echo "phase transition [$TNAME]: check=$(run_check "$TCHECK")"

# 5. Decisions and runway
due=$(pilot_decisions_due agent); [ -n "$due" ] && printf 'DECISION DUE (apply Default, log in ROADMAP.md):\n%s\n' "$due"
hd=$(pilot_decisions_due human); [ -n "$hd" ] && printf 'HUMAN DECISION OVERDUE (does not block the queue):\n%s\n' "$hd"
echo "runway: $(pilot_runway)"

# 6. Anchor and date; the single write
if [ "$APPLY" = 1 ]; then
  sed -e "s/Last commit captured: [^ >-]*/Last commit captured: $HEAD_SHORT/" -e "s/Last updated: [0-9-]*/Last updated: $TODAY/" "$TMP" > "$TD/new" && mv "$TD/new" "$TMP"
  cp "$TMP" "$PILOT"; echo "applied: anchor=$HEAD_SHORT updated=$TODAY ($PILOT)"
else echo "dry run: no changes written (use --apply; add --run-checks to execute Checks)"; fi 2>/dev/null  # consumer may have stopped reading
