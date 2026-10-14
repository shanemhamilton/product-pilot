#!/bin/sh
# Pour: turn [unpoured] tasks under the ACTIVE milestone, then the next milestone, into
# tracker tickets, and write each ticket ID back into the Pilot. Dry run by default.
#
#   --apply              create the tickets and rewrite the tags in place
#   --tracker bd|gh|none bd = Beads (default when .beads exists and bd is on PATH),
#                        gh = GitHub Issues, none = print the payloads only
#   --labels a,b         labels for new tickets; also read from <!-- Pour labels: a,b --> in the Pilot
#   --all                every milestone, not only ACTIVE and the next one
#   --tag N ID           replace the Nth pourable task's [unpoured] with [ID] and exit; use this
#                        for a tracker you drive yourself (for example Linear through an agent tool)
#   --trust-local        allow --apply when the Pilot differs from origin/main
#
# Dedupes by title before creating. Never invents a task: with nothing pourable it prints
# STARVED and exits 0. Ticket text comes from the Pilot, so --apply creates tickets only from a
# Pilot identical to origin/main unless --trust-local is given. The Pilot edit it makes is the
# Owner's to commit, by PR.
set -u
trap "" PIPE  # a consumer that stops reading early must not abort the write-back
. "$(dirname "$0")/pilot-lib.sh"
[ -f "${PILOT:-}" ] || { echo "no PRODUCT_PILOT.md found"; exit 0; }
APPLY=0; TRACKER=""; LABELS=""; ALL=0; TAGN=""; TAGID=""; TRUST=0
while [ $# -gt 0 ]; do case "$1" in
  --apply) APPLY=1;; --tracker) TRACKER="$2"; shift;; --labels) LABELS="$2"; shift;; --all) ALL=1;;
  --tag) TAGN="$2"; TAGID="$3"; shift 2;; --trust-local) TRUST=1;;
  *) echo "usage: $0 [--apply] [--tracker bd|gh|none] [--labels a,b] [--all] [--tag N ID] [--trust-local]" >&2; exit 2;; esac; shift; done
if [ "$APPLY" = 1 ] && [ "$TRUST" = 0 ]; then
  if ! git rev-parse -q --verify origin/main >/dev/null 2>&1; then echo "refusing --apply: no origin/main to compare against (pass --trust-local)"; exit 1
  elif ! git diff --quiet origin/main -- "$PILOT" 2>/dev/null; then echo "refusing --apply: $PILOT differs from origin/main; merge it first or pass --trust-local"; exit 1; fi
fi
[ -z "$LABELS" ] && LABELS=$(grep -m1 -oE 'Pour labels: [^>]+' "$PILOT" | sed 's/Pour labels: //; s/ *--$//; s/ *$//')
if [ -z "$TRACKER" ]; then
  if [ -d .beads ] && command -v bd >/dev/null 2>&1; then TRACKER=bd
  elif command -v gh >/dev/null 2>&1 && git remote get-url origin 2>/dev/null | grep -q github; then TRACKER=gh
  else TRACKER=none; fi
fi
US=$(printf '\037')
# Records: M<US>idx<US>id<US>name<US>active<US>check<US>signal  and  T<US>idx<US>lineno<US>text
REC=$(awk -v US="$US" '
  /^## Active Milestones/ { p=1; next } p && /^## / { p=0 }
  p && /^- \*\*/ {
    m++; line=$0; id=""; if (match(line, /\[[^]]+\]/)) id=substr(line, RSTART, RLENGTH)
    name=line; sub(/^- \*\*/, "", name); sub(/\*\*.*$/, "", name); sub(/^\[[^]]+\] */, "", name)
    act=(line ~ /(← ACTIVE|<- ACTIVE)[[:space:]]*$/) ? 1 : 0
    mid[m]=id; mname[m]=name; mact[m]=act; next }
  p && m && /^[[:space:]]*- Check:/ { c=$0; sub(/^[^`]*`/, "", c); sub(/`.*$/, "", c); mcheck[m]=c; next }
  p && m && /^[[:space:]]*- Completion signal:/ { s=$0; sub(/^[[:space:]]*- Completion signal:[[:space:]]*/, "", s); msig[m]=s; next }
  p && m && /^[[:space:]]*- \[ \] \[unpoured\] / { t=$0; sub(/^[[:space:]]*- \[ \] \[unpoured\] /, "", t); printf "T%s%d%s%d%s%s\n", US, m, US, NR, US, t; next }
  END { for (i=1; i<=m; i++) printf "M%s%d%s%s%s%s%s%d%s%s%s%s\n", US, i, US, mid[i], US, mname[i], US, mact[i], US, mcheck[i], US, msig[i] }' "$PILOT")
ACTIVE_IDX=$(printf '%s\n' "$REC" | awk -F"$US" '$1=="M" && $5==1 {print $2; exit}')
[ -z "$ACTIVE_IDX" ] && { echo "no ACTIVE milestone found in $PILOT"; exit 1; }
in_scope() { [ "$ALL" = 1 ] || [ "$1" = "$ACTIVE_IDX" ] || [ "$1" = "$((ACTIVE_IDX + 1))" ]; }
mfield() { printf '%s\n' "$REC" | awk -F"$US" -v i="$1" -v f="$2" '$1=="M" && $2==i {print $f; exit}'; }
HEAD_SHORT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
TD=$(mktemp -d) || exit 2; trap 'rm -rf "$TD"' EXIT  # private scratch dir; no predictable names
TMPBODY="$TD/body"
write_tag() { awk -v n="$1" -v id="$2" 'NR==n { sub(/\[unpoured\]/, "[" id "]") } { print }' "$PILOT" > "$TD/new" && mv "$TD/new" "$PILOT"; }
N=0
printf '%s\n' "$REC" | awk -F"$US" '$1=="T"' | while IFS="$US" read -r _ idx lineno text; do
  in_scope "$idx" || continue
  N=$((N + 1))
  MID=$(mfield "$idx" 3); MNAME=$(mfield "$idx" 4); CHECK=$(mfield "$idx" 6); SIG=$(mfield "$idx" 7)
  if [ -n "$TAGN" ]; then
    [ "$N" = "$TAGN" ] || continue
    write_tag "$lineno" "$TAGID"; echo "tagged task $N as [$TAGID]: $text"; exit 0
  fi
  echo "$N. $MID $MNAME :: $text"
  [ "$APPLY" = 1 ] || continue
  printf 'Poured from %s at %s on %s.\nMilestone: %s %s\nCompletion signal: %s\nCheck: %s\n' "$PILOT" "$HEAD_SHORT" "$TODAY" "$MID" "$MNAME" "$SIG" "$CHECK" > "$TMPBODY"
  ACC="Milestone Check: ${CHECK:-none}. ${SIG}"
  ID=""
  case "$TRACKER" in
    bd)
      ID=$(bd list --title "$text" -s open,in_progress,blocked --json 2>/dev/null | grep -m1 -o '"id": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
      if [ -n "$ID" ]; then echo "   exists: $ID"; else
        # shellcheck disable=SC2086
        ID=$(bd create --body-file "$TMPBODY" --acceptance "$ACC" ${LABELS:+-l "$LABELS"} --silent -- "$text" 2>/dev/null | tail -1)
        [ -n "$ID" ] && echo "   created: $ID"
      fi ;;
    gh)
      ID=$(gh issue list --state open --search "\"$text\" in:title" --json number --jq '.[0].number' 2>/dev/null)
      if [ -n "$ID" ]; then ID="#$ID"; echo "   exists: $ID"; else
        # shellcheck disable=SC2086
        URL=$(gh issue create --title "$text" --body-file "$TMPBODY" ${LABELS:+--label "$LABELS"} 2>/dev/null)
        [ -n "$URL" ] && { ID="#${URL##*/}"; echo "   created: $ID $URL"; }
      fi ;;
    none) echo "   payload:"; sed 's/^/     /' "$TMPBODY"; continue ;;
  esac
  [ -n "$ID" ] || { echo "   FAILED to create a ticket with $TRACKER; tag left as [unpoured]" >&2; continue; }
  write_tag "$lineno" "$ID"
done
COUNT=$(printf '%s\n' "$REC" | awk -F"$US" -v a="$ACTIVE_IDX" -v all="$ALL" '$1=="T" && (all==1 || $2==a || $2==a+1)' | grep -c . || true)
if [ -n "$TAGN" ]; then [ "$COUNT" -ge "$TAGN" ] || { echo "no pourable task number $TAGN (found $COUNT)" >&2; exit 1; }; exit 0; fi
if [ "$COUNT" = 0 ]; then echo "STARVED: no [unpoured] tasks under the ACTIVE milestone$([ "$ALL" = 1 ] || printf ' or the next one'); report to the Pilot Owner"; exit 0; fi
if [ "$APPLY" = 1 ]; then echo "poured with $TRACKER; $PILOT updated in place, commit it by PR (Owner)"; else echo "dry run: $COUNT pourable task(s); tracker=$TRACKER; add --apply to create tickets"; fi
