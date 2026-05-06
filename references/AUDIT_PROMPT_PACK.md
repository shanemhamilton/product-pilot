# Product Pilot — 5-Angle Audit Prompt Pack

This file is a reference pack for tenants and contributors. It contains the five audit angles required to evaluate a Product Pilot in production, plus the verification grep-checks and the challenge-all-positive gate.

Run all five angles. Dropping an angle blinds you to a class of defect — the angle list below was derived from real production failures, and each angle catches defects no other angle reliably surfaces.

---

## How to use this pack

1. Run angles 1-5 in order. Each angle outputs its own findings independently — do not let a clean run on angle 2 soften angle 3.
2. After all five angles complete, run the **Verification grep-checks** section. The grep-checks are deterministic; they catch invariant violations the angle prompts can miss.
3. Apply the **Challenge-all-positive gate** as the final step. Any verifier or angle that returned all-PASS gets re-prompted under the gate.
4. Aggregate findings. Lead with the worst defect across all angles. Do not cluster by angle in the output — cluster by severity.

The pack assumes the auditing agent has read access to the Pilot, the supporting docs in the same directory, the host repo's git log, and the host repo's `.gitignore` and any agent instruction file (CLAUDE.md, AGENTS.md, .cursorrules).

---

## Anti-sycophancy quotas (apply to every angle)

These rules apply to every angle below. Any angle that violates them is a failed audit, regardless of findings.

- **Lead with the worst defect.** No "overall the Pilot is solid" openers. No closing encouragement.
- **Quotas:** ≥5 defects required for a full Pilot audit. ≥3 defects for a single-angle review. Soft audits produce false confidence.
- **Banned softening words:** good, great, solid, clean, comprehensive, thorough, well-structured, excellent, impressive, nice, effective, polished. Also banned: "overall", "for the most part", "broadly speaking", "looks right".
- **Specificity required.** Unacceptable: "the metrics section is unclear." Acceptable: "Metrics Snapshot lists D7 retention with target 30% but METRICS_AND_OKRS.md lists 25% — Pilot disagrees with its own source of truth."
- **No FAIL softened to CONDITIONAL PASS.** If quotas or specificity standards are not met, issue FAIL.

---

## Angle 1 — Drift / Staleness

**Goal:** Detect places where the Pilot has fallen behind reality.

**Prompt:**

> You are auditing PRODUCT_PILOT.md for drift between what the Pilot claims and what is true in the codebase right now. Run the checks below and report ≥3 drift defects. Lead with the worst.
>
> 1. Compare `Last commit captured` in the Pilot header to `git rev-parse --short HEAD`. If they diverge by more than 10 commits, the Pilot is structurally stale; report it as a critical drift defect.
> 2. Run `git log --oneline --since=<Last updated date>` and compare commit messages to the Pilot's Recent Shipped section. Any commit group not represented is a drift defect.
> 3. For every milestone marked `← ACTIVE`, search the codebase for evidence that the milestone tasks are actually still in flight. A milestone whose tasks all show shipped commits but whose Pilot checkbox is unchecked is a drift defect.
> 4. For every metric in Metrics Snapshot, check whether METRICS_AND_OKRS.md agrees on target and current. Any mismatch is a drift defect.
> 5. For every blocker in "What's Blocking Ship", verify the blocker still exists. A "blocker" already resolved by a recent commit is a drift defect.
> 6. Inspect the Pilot's `Last updated` date. If it is more than 30 days old AND the repo has had more than 10 commits in that window, this combination is a drift defect even if individual claims happen to be accurate.
>
> Banned softening words: good, solid, clean, comprehensive, thorough. Lead with the worst defect — do NOT open with "the Pilot is mostly accurate" or similar.

---

## Angle 2 — Coverage Gaps

**Goal:** Detect things that *should* be in the Pilot but are not.

**Prompt:**

> You are auditing PRODUCT_PILOT.md for coverage gaps — material work, decisions, or risks that exist in the project but do not appear in the Pilot. Report ≥3 coverage defects. Lead with the worst.
>
> 1. Run `git log --oneline --since=<Recent Shipped heading date>` and identify any commit group representing a feature, infrastructure change, or major refactor that does NOT appear in Recent Shipped. Each is a coverage defect.
> 2. Search the project for `TODO`, `FIXME`, and recently-modified design or planning docs. Any major in-flight workstream not represented in Active Milestones is a coverage defect.
> 3. Check the Decision Pending section. If the project has unresolved architectural or product decisions visible in commit messages, PRs, or supporting docs, but the Decision Pending table is empty or minimal, that is a coverage defect.
> 4. Check the Open Tooling Gaps section. Known harness limitations (no SessionStart hook, doc-only session-end enforcement, no pre-commit doc check) MUST be acknowledged here unless explicitly enforced. An empty Open Tooling Gaps section in a project without enforcement is a coverage defect — the Pilot is pretending enforcement exists.
> 5. Verify the Metrics Snapshot covers all AARRR families relevant to the current phase. A Pilot listing only Engagement metrics in a Monetize-phase product is a coverage defect.
>
> Banned softening words: good, solid, clean, comprehensive, thorough. Lead with the worst gap.

---

## Angle 3 — Structure / Usability

**Goal:** Detect Pilot structure that buries critical information or reads like prose where it should read like data.

**Prompt:**

> You are auditing PRODUCT_PILOT.md for structural defects that reduce its usability for an AI agent reading top-down. Report ≥3 structural defects. Lead with the worst.
>
> 1. Verify the section order: header comments → Quick Orientation (with bulletized "What's Blocking Ship") → Agent Operating Instructions → Active Milestones → Decision Pending → Recent Shipped → Phase Transitions → Metrics Snapshot → Open Tooling Gaps → Product Docs Index → Changelog. Any section out of order is a structural defect, especially Agent Operating Instructions appearing AFTER milestone history.
> 2. Verify "What's Blocking Ship" is bulletized (one bullet per blocker, with unblock condition / owner / since date). Any prose paragraph in this section is a structural defect.
> 3. Verify the Pilot is under 140 lines when filled. Over 140 lines means operational detail belongs in supporting docs.
> 4. Verify exactly ONE milestone has the `← ACTIVE` marker. Zero or multiple is a structural defect.
> 5. Verify Phase Transitions shows ONLY the next transition, not full transition history. Full tables belong in ROADMAP.md.
> 6. Verify the Product Docs Index has both Review cadence AND Last reviewed columns. Cadence without per-doc timestamps is non-actionable.
> 7. Verify Decision Pending and Open Tooling Gaps sections exist (even if empty with placeholder text). Their absence is a structural defect — empty sections force tenants to surface gaps; missing sections let gaps stay invisible.
>
> Banned softening words: good, well-structured, clean, intuitive, readable. Do NOT close with "with these fixes the structure will be solid".

---

## Angle 4 — Sister-Doc Consistency

**Goal:** Detect contradictions between the Pilot and the supporting docs in the same directory.

**Prompt:**

> You are auditing PRODUCT_PILOT.md against its sister docs (PRODUCT_OVERVIEW.md, FEATURE_INVENTORY.md, ROADMAP.md, METRICS_AND_OKRS.md, USER_RESEARCH.md, COMPETITIVE_LANDSCAPE.md — whichever exist). Report ≥3 consistency defects. Lead with the worst.
>
> 1. Cross-check every milestone in the Pilot's Active Milestones against ROADMAP.md. Any milestone present in one and absent in the other, or with different completion signals or dependencies, is a consistency defect.
> 2. Cross-check every metric in Metrics Snapshot against METRICS_AND_OKRS.md. Any mismatch in target, current value, or definition is a consistency defect.
> 3. Cross-check phase claims. The Pilot's `Current phase` must match ROADMAP.md's "Current" phase header. Mismatch is a consistency defect.
> 4. Cross-check feature claims. Anything in Recent Shipped that should be in FEATURE_INVENTORY.md but is not is a consistency defect.
> 5. Cross-check decision references. Anything in the Pilot's Decision Pending that does NOT appear in ROADMAP.md's Decision Log when resolved is a consistency defect.
> 6. Verify the Last reviewed dates in the Pilot's Product Docs Index match the `<!-- Last reviewed: -->` header comments in each sister doc. Any mismatch is a consistency defect.
>
> Banned softening words: aligned, consistent, in sync. Use "matches" or "diverges" — those are testable.

---

## Angle 5 — Session Compliance

**Goal:** Detect places where the Pilot or the surrounding harness pretends enforcement exists when it does not.

**Prompt:**

> You are auditing whether the Product Pilot system in this project actually enforces what it claims to enforce. Report ≥3 compliance defects. Lead with the worst.
>
> 1. Check whether the host harness has a SessionStart hook that reads PRODUCT_PILOT.md. If the agent instruction file (CLAUDE.md, AGENTS.md, .cursorrules) says the agent MUST read the Pilot, but no hook enforces it, that is a compliance defect (doc-only enforcement masquerading as a rule).
> 2. Check whether session-end doc updates are enforced. Search for a pre-commit hook, CI step, or other check that fails when code changes ship without corresponding Pilot/sister-doc updates. If none exists but the Pilot's Session End checklist reads as a rule, that is a compliance defect.
> 3. Check whether `.gitignore` excludes the product docs directory. If `docs/`, `documentation/`, or the Pilot's parent directory is gitignored, the Pilot is not version-controlled — every claim of "tracked" or "audited" is a compliance defect.
> 4. Run the agent's own self-report. If you can find telemetry, transcripts, or host session history, count actual skill invocations vs claimed cadence. A skill that claims session-start firing but invoked zero times in the recent window is a critical compliance defect.
> 5. Check whether the agent instruction file actually contains the Product Pilot reference block from `references/AGENT_INSTRUCTION_REFERENCE.md`. Missing block is a compliance defect.
>
> Banned softening words: enforced, mandatory, ensured. These words must be backed by a hook, check, or test, or they are sycophancy. Lead with the worst gap between claim and enforcement.

---

## Verification grep-checks (run after all five angles)

These are deterministic shell checks that catch invariant violations regardless of audit findings. Run them all. Each FAIL is a defect.

> Run these against a **filled tenant Pilot**, not the unfilled `templates/PRODUCT_PILOT_TEMPLATE.md`. By design the unfilled template contains `[PLACEHOLDER:]` markers and exceeds 140 lines (it includes explanatory HTML comments that get trimmed when filled). The grep-checks describe the contract for tenant Pilots, not for the template source.

```bash
# All commands run from the host repo root.

# 1. Product docs directory must NOT be gitignored. (Replace docs/product/ with the actual path.)
PRODUCT_DOCS="docs/product/"
git check-ignore -q "$PRODUCT_DOCS" && echo "FAIL: product docs directory is gitignored — Pilot will never be version-controlled"

# 2. No [PLACEHOLDER:] markers may survive in any product doc.
grep -rn "\[PLACEHOLDER:" "$PRODUCT_DOCS" && echo "FAIL: unfilled placeholders survive in generated docs"

# 3. Exactly one milestone marked ← ACTIVE in PRODUCT_PILOT.md.
# Match only end-of-line applications (the milestone bullet), not instructional
# references inside backticks or HTML comments.
ACTIVE_COUNT=$(grep -cE "(← ACTIVE|<- ACTIVE)\s*$" "$PRODUCT_DOCS/PRODUCT_PILOT.md")
[ "$ACTIVE_COUNT" -eq 1 ] || echo "FAIL: PRODUCT_PILOT.md has $ACTIVE_COUNT applied ACTIVE markers (expected 1)"

# 4. Last commit captured header must match a real commit.
LAST_HASH=$(grep -oE "Last commit captured: [a-f0-9]+" "$PRODUCT_DOCS/PRODUCT_PILOT.md" | awk '{print $4}')
git cat-file -e "$LAST_HASH" 2>/dev/null || echo "FAIL: Last commit captured header references unknown commit $LAST_HASH"

# 5. Required sections must all be present.
for SECTION in "## Quick Orientation" "## Agent Operating Instructions" "## Active Milestones" "## Decision Pending" "## Recent Shipped" "## Phase Transitions" "## Metrics Snapshot" "## Open Tooling Gaps" "## Product Docs Index" "## Changelog"; do
  grep -qF "$SECTION" "$PRODUCT_DOCS/PRODUCT_PILOT.md" || echo "FAIL: missing section: $SECTION"
done

# 6. Pilot under 140 lines (filled tenant Pilots; loosen for unfilled template).
LINES=$(wc -l < "$PRODUCT_DOCS/PRODUCT_PILOT.md")
[ "$LINES" -le 140 ] || echo "FAIL: PRODUCT_PILOT.md is $LINES lines (target: <=140)"
```

These checks are MANDATORY as the final gate before declaring an audit complete. Two prior verifier agents all-PASS does not substitute for the grep-checks — verifier agents miss invariants like a gitignored docs directory.

---

## Challenge-all-positive gate

If any angle or any verifier returned all-PASS, re-prompt as follows. Do not skip this step.

> The previous audit returned all-PASS or near-all-PASS. This is statistically improbable given the failure rate of Pilots in production (the average production Pilot has 10+ defects across 5 angles).
>
> Re-audit using the same angle prompt, but treat the all-PASS result as evidence that you missed something, not as evidence that the Pilot is correct. Specifically:
>
> 1. List ALL claims in the Pilot that you accepted as true on the first pass. For each, identify the source you used to verify it. If you used the Pilot itself as the source, that is circular — re-verify against the codebase, git log, or supporting doc.
> 2. Identify at least three claims you did NOT verify on the first pass. Verify them now.
> 3. Compare your re-audit findings to the first pass. Any new defect that should have been caught is itself a meta-defect: the verifier is sycophantic.
> 4. Issue a final FAIL or PASS based on the re-audit. A second all-PASS at this stage is acceptable only if accompanied by a list of ≥5 specific verifications you ran the second time that you skipped the first time.

This gate exists because verifier sycophancy is a known failure mode: two verifiers can return all-PASS on a Pilot with 6 critical defects when neither verifier executed the grep-checks.
