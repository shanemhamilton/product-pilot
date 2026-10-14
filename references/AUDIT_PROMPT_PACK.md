# Product Pilot — Deep Review Prompt Pack

Optional. Use it for a Full-scope Pilot before a phase transition, or when a Pilot has not been reconciled in a month. The deterministic contract is enforced by `scripts/pilot-grep-checks.sh`; run that first and always. Lean-scope Pilots usually need only the script and Angle 1.

## How to use this pack

1. Run `scripts/pilot-grep-checks.sh --ci` from the repo root. Fix every FAIL before reading further.
2. Run the angles that apply. Each angle reports independently; a clean result on one does not soften another.
3. Aggregate by severity, worst first. Do not cluster by angle.

## Review standards (apply to every angle)

- Lead with the worst verified defect. No "overall" openers, no closing encouragement.
- Report every defect that survives verification, and list the checks that found none. Do not pad to a count and do not stop at one.
- Be specific. Unacceptable: "the metrics section is unclear." Acceptable: "Metrics Snapshot row D7 return has no Source; the value 28% cannot be reproduced."
- Banned softening words: good, great, solid, clean, comprehensive, thorough, well-structured, excellent, impressive, nice, effective, polished, overall, broadly, "looks right".
- A claim verified only against the Pilot itself is circular. Verify against git, the tracker, the Check output, or the supporting doc.

---

## Angle 1 — Drift

**Goal:** places where the Pilot has fallen behind reality.

> Audit PRODUCT_PILOT.md for drift between what it claims and what git, the tracker, and the Checks show now. Lead with the worst verified defect and list the checks that found none.
>
> 1. Compare `Last commit captured` with `git rev-parse --short HEAD`. More than 10 commits apart is a drift defect; run `scripts/pilot-reconcile.sh` and compare its Recent Shipped output with the section in the file.
> 2. For the `← ACTIVE` milestone, run its `Check` command. A passing Check with unticked tasks, or ticked tasks whose tickets are still open, is a drift defect.
> 3. For every task tagged with a ticket ID, read the ticket state. Closed ticket and unticked box, or the reverse, is a drift defect.
> 4. For every blocker in "What's Blocking Ship", verify it still blocks a release: the PR is unmerged, the build is red, the readback is missing. A resolved blocker still listed is a drift defect.
> 5. For every Decision Pending row with Tier `agent` and a Deadline in the past, the Default should already have been applied and logged in ROADMAP.md. If not, that is a drift defect.
> 6. For every Metrics Snapshot row, run the Source. A Current value that differs from the Source output, or a row with no Source, is a drift defect.

---

## Angle 2 — Coverage

**Goal:** material work, decisions, or risks that exist in the project but not in the Pilot.

> Audit PRODUCT_PILOT.md for coverage gaps. Lead with the worst verified gap and list the checks that found none.
>
> 1. Run `git log --oneline --since=<Recent Shipped heading date>`. Any user-visible change, infrastructure change, or release not represented in Recent Shipped, after regeneration, is a coverage defect.
> 2. Read the tracker's open items for this project. In-flight work with no task under Active Milestones is a coverage defect unless it is maintenance.
> 3. Unresolved product or architecture choices visible in PRs, tracker comments, or docs that are absent from Decision Pending are coverage defects.
> 4. Open Tooling Gaps must list the gaps from `TOOLING_GAPS.md` that apply to this repo: no CI check, no scheduled reconcile, workers that receive no banner. An empty section in a repo with any of these is a coverage defect.
> 5. Runway: if the ACTIVE milestone has no open task and no milestone has `[unpoured]` tasks, the pipeline will starve. That is a coverage defect in the roadmap.

---

## Angle 3 — Structure

**Goal:** structure that buries what an agent needs first, or reads as prose where it should read as data.

> Audit PRODUCT_PILOT.md for structural defects against format 3.0. Lead with the worst verified defect and list the checks that found none.
>
> 1. Section order: header comments, Quick Orientation with "What's Blocking Ship", Agent Operating Instructions, Active Milestones, Decision Pending, Recent Shipped, Phase Transitions, Metrics Snapshot, Open Tooling Gaps, Product Docs Index (Full scope only), Changelog. Out of order is a defect.
> 2. "What's Blocking Ship" is bullets with unblock condition, owner, ticket, since-date. Prose is a defect. A blocker that describes work rather than a release gate is a defect.
> 3. Exactly one `← ACTIVE`, at the end of its line.
> 4. Every task carries `[TICKET]` or `[unpoured]`. Every milestone has a `Check` with one backticked command or `manual — …`, and a Completion signal. A milestone with more than six tasks is a defect.
> 5. Decision Pending has seven columns and every row has a Tier, a Default, and a Deadline.
> 6. Phase Transitions holds one row with a Check column. A date-based or research-based trigger is a defect.
> 7. 140 lines or fewer. Decision Pending and Open Tooling Gaps exist even when empty.

---

## Angle 4 — Supporting-doc consistency (Full scope)

**Goal:** contradictions between the Pilot and the docs in the same directory. Lean scope checks only ROADMAP.md.

> Audit PRODUCT_PILOT.md against its supporting docs. Lead with the worst verified defect and list the checks that found none. Use "matches" or "diverges"; "aligned" and "consistent" are banned.
>
> 1. Every milestone in Active Milestones appears in ROADMAP.md with the same tasks, Check, and dependency.
> 2. Every row in Metrics Snapshot appears in METRICS_AND_OKRS.md with the same Source, target, and current value.
> 3. The Pilot's phase matches ROADMAP.md's current phase.
> 4. Every Decision Pending row that was resolved appears in the ROADMAP.md Decision Log with how it was decided.
> 5. Recent Shipped items that are features appear in FEATURE_INVENTORY.md.
> 6. Product Docs Index "Last reviewed" dates match each doc's `Last reviewed` header.

---

## Angle 5 — Enforcement

**Goal:** claims of enforcement that nothing enforces in this repo.

> Audit whether this repo enforces the Pilot contract. Lead with the worst gap between claim and mechanism, and list the checks that found none. The words enforced, mandatory, and ensured are banned unless a hook, CI job, or script backs them.
>
> 1. Is `scripts/pilot-banner.sh` wired into a SessionStart hook, and does the dispatcher paste its output into packets? Absent either, workers may never see the Pilot.
> 2. Does a pre-commit hook run `pilot-grep-checks.sh --pre-commit`? Does CI run `--ci` on pull requests? A repo with neither has no structural guarantee.
> 3. Is `pilot-reconcile.sh --apply` scheduled or run post-merge by the Owner? If nothing runs it, Recent Shipped and the ACTIVE marker drift.
> 4. Does the instruction file carry the reference block inside the section that packets copy? A pointer outside that section is a defect.
> 5. Is the product docs directory gitignored? If yes, every claim of tracking is hollow.
> 6. Does the Pilot's Open Tooling Gaps section name each gap found above? If a gap exists and the section is silent, that is a defect.

---

## Challenge-all-positive gate

If an angle returned no defects, re-run it once under this prompt:

> The previous pass found nothing. Treat that as a signal that something was not verified. List every claim you accepted on the first pass and the source you used. Any claim verified only against the Pilot is circular; verify it now against git, the tracker, a Check, or the supporting doc. Report what you ran the second time and what, if anything, changed.

A second clean pass is acceptable when it lists the verifications run.
