#!/bin/sh
# Pour: turn [unpoured] tasks under the ACTIVE milestone, then the next milestone, into
# tracker tickets, and write each ticket ID back into the Pilot. Dry run by default.
#
#   --apply              create the tickets and rewrite the tags in place
#   --tracker bd|gh|linear|none
#                        bd = Beads (default when .beads exists and bd is on PATH),
#                        linear = Linear (default when LINEAR_API_KEY is set and the Pilot has a
#                        <!-- Linear team: KEY --> comment), gh = GitHub Issues (default with a
#                        GitHub origin), none = print the payloads only
#   --team KEY           Linear team key; also read from the Linear team comment
#   --labels a,b         labels for new tickets; also read from <!-- Pour labels: a,b --> in the Pilot.
#                        Linear tickets also get "Pilot: <product> — <milestone>"
#   --all                every milestone, not only ACTIVE and the next one
#   --tag N ID           replace the Nth pourable task's [unpoured] with [ID] and exit; use this
#                        for a tracker the script cannot drive
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
APPLY=0; TRACKER=""; LABELS=""; ALL=0; TAGN=""; TAGID=""; TRUST=0; TEAM=""; TEAM_ID=""
while [ $# -gt 0 ]; do case "$1" in
  --apply) APPLY=1;; --tracker) TRACKER="$2"; shift;; --labels) LABELS="$2"; shift;; --all) ALL=1;;
  --tag) TAGN="$2"; TAGID="$3"; shift 2;; --trust-local) TRUST=1;; --team) TEAM="$2"; shift;;
  *) echo "usage: $0 [--apply] [--tracker bd|gh|linear|none] [--team KEY] [--labels a,b] [--all] [--tag N ID] [--trust-local]" >&2; exit 2;; esac; shift; done
if [ "$APPLY" = 1 ] && [ "$TRUST" = 0 ]; then
  if ! git rev-parse -q --verify origin/main >/dev/null 2>&1; then echo "refusing --apply: no origin/main to compare against (pass --trust-local)"; exit 1
  elif ! git diff --quiet origin/main -- "$PILOT" 2>/dev/null; then echo "refusing --apply: $PILOT differs from origin/main; merge it first or pass --trust-local"; exit 1; fi
fi
[ -z "$LABELS" ] && LABELS=$(grep -m1 -oE 'Pour labels: [^>]+' "$PILOT" | sed 's/Pour labels: //; s/ *--$//; s/ *$//')
[ -z "$TEAM" ] && TEAM=$(grep -m1 -oE 'Linear team: [A-Z][A-Z0-9]*' "$PILOT" | awk '{print $3}')
if [ -z "$TRACKER" ]; then
  if [ -d .beads ] && command -v bd >/dev/null 2>&1; then TRACKER=bd
  elif [ -n "${LINEAR_API_KEY:-}" ] && [ -n "$TEAM" ]; then TRACKER=linear
  elif command -v gh >/dev/null 2>&1 && git remote get-url origin 2>/dev/null | grep -q github; then TRACKER=gh
  else TRACKER=none; fi
fi
if [ "$TRACKER" = linear ]; then
  [ -n "${LINEAR_API_KEY:-}" ] || { echo "linear: set LINEAR_API_KEY" >&2; exit 1; }
  [ -n "$TEAM" ] || { echo "linear: pass --team KEY or add <!-- Linear team: KEY --> to $PILOT" >&2; exit 1; }
  if [ "$APPLY" = 1 ]; then
    TEAM_ID=$(linear_gql 'query($key: String!) { teams(filter: { key: { eq: $key } }) { nodes { id } } }' "{\"key\":\"$TEAM\"}" | json_field id)
    [ -n "$TEAM_ID" ] || { echo "linear: no team with key $TEAM" >&2; exit 1; }
  fi
fi
# Product name for the Linear label: the first bold span of Quick Orientation's first line, else its first word.
PRODUCT=$(awk '/^## Quick Orientation/{p=1; next} p && /^(#|---)/{exit} p && NF && !/^<!--/ {print; exit}' "$PILOT" | sed -E 's/^[^*]*\*\*([^*]+)\*\*.*/\1/; s/\*\*//g' | awk '{print $1}' | tr -d ',.:;')
linear_label_ids() { # $1 = comma-separated names; prints "id","id", creating a missing label in the team
  out=""; IFS=,; for n in $1; do unset IFS
    n=$(printf '%s' "$n" | sed 's/^ *//; s/ *$//'); [ -n "$n" ] || continue; nj=$(printf '%s' "$n" | json_str)
    id=$(linear_gql 'query($name: String!) { issueLabels(filter: { name: { eq: $name } }) { nodes { id team { key } } } }' "{\"name\":\"$nj\"}" \
      | grep -oE "\{\"id\":\"[^\"]+\",\"team\":(null|\{\"key\":\"$TEAM\"\})\}" | head -1 | json_field id)
    [ -n "$id" ] || id=$(linear_gql 'mutation($name: String!, $teamId: String!) { issueLabelCreate(input: { name: $name, teamId: $teamId }) { issueLabel { id } } }' "{\"name\":\"$nj\",\"teamId\":\"$TEAM_ID\"}" | json_field id)
    [ -n "$id" ] && out="${out:+$out,}\"$id\""
  done; unset IFS; printf '%s' "$out"
}
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
    linear)
      TJ=$(printf '%s' "$text" | json_str)
      R=$(linear_gql 'query($key: String!, $title: String!) { issues(first: 1, filter: { team: { key: { eq: $key } }, title: { eq: $title }, state: { type: { nin: ["completed", "canceled"] } } }) { nodes { identifier } } }' "{\"key\":\"$TEAM\",\"title\":\"$TJ\"}")
      case "$R" in *'"nodes"'*) ;; *) echo "   FAILED: Linear dedupe query returned no result; tag left as [unpoured]" >&2; continue;; esac
      ID=$(printf '%s' "$R" | json_field identifier)
      if [ -n "$ID" ]; then echo "   exists: $ID"; else
        LIDS=$(linear_label_ids "$LABELS,Pilot: $PRODUCT — $MID $MNAME")
        R=$(linear_gql 'mutation($input: IssueCreateInput!) { issueCreate(input: $input) { issue { identifier url } } }' \
          "{\"input\":{\"teamId\":\"$TEAM_ID\",\"title\":\"$TJ\",\"description\":\"$(json_str < "$TMPBODY")\"${LIDS:+,\"labelIds\":[$LIDS]}}}")
        ID=$(printf '%s' "$R" | json_field identifier); [ -n "$ID" ] && echo "   created: $ID $(printf '%s' "$R" | json_field url)"
      fi ;;
    none) echo "   payload:"; sed 's/^/     /' "$TMPBODY"; continue ;;
  esac
  [ -n "$ID" ] || { echo "   FAILED to create a ticket with $TRACKER; tag left as [unpoured]" >&2; continue; }
  write_tag "$lineno" "$ID"
done
COUNT=$(printf '%s\n' "$REC" | awk -F"$US" -v a="$ACTIVE_IDX" -v all="$ALL" '$1=="T" && (all==1 || $2==a || $2==a+1)' | grep -c . || true)
if [ -n "$TAGN" ]; then [ "$COUNT" -ge "$TAGN" ] || { echo "no pourable task number $TAGN (found $COUNT)" >&2; exit 1; }; exit 0; fi
if [ "$COUNT" = 0 ]; then echo "STARVED: no [unpoured] tasks under the ACTIVE milestone$([ "$ALL" = 1 ] || printf ' or the next one'); report to the Pilot Owner"; exit 0; fi
{ if [ "$APPLY" = 1 ]; then echo "poured with $TRACKER; $PILOT updated in place, commit it by PR (Owner)"; else echo "dry run: $COUNT pourable task(s); tracker=$TRACKER$([ "$TRACKER" = linear ] && printf " team=%s" "$TEAM"); add --apply to create tickets"; fi; } 2>/dev/null  # consumer may have stopped reading
