# Product Pilot

<!-- MANDATORY: Read this file at the start of every session. -->
<!-- Product Pilot format version: 2.2 -->
<!-- Pilot scope: [PLACEHOLDER: SCOPE — Full | Lite | Micro] -->
<!-- Last updated: [PLACEHOLDER: DATE] -->
<!-- Last commit captured: [PLACEHOLDER: SHORT_HASH — the most recent commit this Pilot has been reconciled against. Update with `git rev-parse --short HEAD` whenever this Pilot is edited.] -->
<!-- Owner: [PLACEHOLDER: OWNER_NAME] -->
<!-- Target: under 140 lines. Move operational detail (commit hashes inside milestones, sub-task tracking, full transition tables) to supporting docs when this file grows. -->

## Quick Orientation

[PLACEHOLDER: PRODUCT_DESCRIPTION — 2-3 sentences describing what the product does and who it's for]

**Current phase:** [PLACEHOLDER: PHASE_NUMBER] — [PLACEHOLDER: PHASE_NAME]
**Deep context:** See the supporting docs indexed at the bottom of this file.

### What's Blocking Ship

<!-- BULLETIZED. Each blocker = one bullet with what unblocks it, the owner, and a since-date.
     If you find yourself writing prose paragraphs here, you are doing it wrong — the structure
     exists to force specificity. Two-three blockers max; older ones move to a supporting doc. -->

- **[PLACEHOLDER: BLOCKER_NAME]** — Unblocked when: [PLACEHOLDER: CONDITION]. Owner: [PLACEHOLDER: NAME]. Since: [PLACEHOLDER: DATE]
- **[PLACEHOLDER: BLOCKER_NAME]** — Unblocked when: [PLACEHOLDER: CONDITION]. Owner: [PLACEHOLDER: NAME]. Since: [PLACEHOLDER: DATE]

---

## Agent Operating Instructions

<!-- This section is intentionally placed BEFORE milestone state and history. Read these
     instructions before you interpret any milestone, blocker, or shipped-work claim below. -->

### Session Start

1. Read this Pilot file end-to-end before starting work
2. Verify the `Last commit captured` header against `git rev-parse --short HEAD`. If they differ by more than ~10 commits, run the Recent Shipped regenerate command before continuing — the Pilot is behind reality
3. Identify the `← ACTIVE` milestone
4. If your work relates to a product doc (see Product Docs Index), load the relevant PM skill if installed
5. If the `← ACTIVE` milestone has all tasks checked off, prompt: "Milestone [X] appears complete. Should we advance `← ACTIVE` to the next milestone?"
6. If `Last updated` is more than 30 days ago, prompt for a Pilot review before starting new work
7. In the Product Docs Index, scan the `Last reviewed` column — flag any doc more than 30 days stale: "[DOC] hasn't been reviewed in over 30 days. Consider updating it this session or scheduling a review."
8. If your current task doesn't align with the `← ACTIVE` milestone, proceed with your task but note the divergence. At session end, consider whether this Pilot needs updating to reflect the actual workstream

**Context depth by task type:**
- **Quick task** (bug fix, config change): Read only this Pilot
- **Feature work**: Read this Pilot + `FEATURE_INVENTORY.md` + `ROADMAP.md`
- **Strategic work** (new phase, pivot, major planning): Read all docs in this directory

### Session End — Update relevant docs alongside code changes

<!-- Honest framing: this checklist is documentation-only unless the host harness adds enforcement
     (pre-commit hook, CI check). See OPEN TOOLING GAPS below. Skip if changes were trivial
     (typo fixes, config tweaks, non-functional). -->

| Work type | Update this doc | Skill (if available) |
|-----------|----------------|----------------------|
| Feature shipped | `FEATURE_INVENTORY.md` | `feature-spec` |
| Milestone complete | `ROADMAP.md` + this Pilot | `roadmap-management` |
| New metric data | `METRICS_AND_OKRS.md` | `metrics-tracking` |
| User insight | `USER_RESEARCH.md` | `user-research-synthesis` |
| Competitive intel | `COMPETITIVE_LANDSCAPE.md` | `competitive-analysis` |

When you edit this Pilot, also update `Last updated` and `Last commit captured` in the header.

---

## Active Milestones

### [PLACEHOLDER: PHASE_NAME]

<!-- 2-4 milestones typical. Delete unused blocks. Exactly ONE milestone marked ← ACTIVE. -->

- **[PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME]** ← ACTIVE
  - [ ] [PLACEHOLDER: TASK_1]
  - [ ] [PLACEHOLDER: TASK_2]
  - Completion signal: [PLACEHOLDER: HOW_TO_KNOW_ITS_DONE]

- **[PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME]**
  - [ ] [PLACEHOLDER: TASK_1]
  - [ ] [PLACEHOLDER: TASK_2]
  - Completion signal: [PLACEHOLDER: HOW_TO_KNOW_ITS_DONE]
  - Dependency: [PLACEHOLDER: UPSTREAM_MILESTONE]

### [PLACEHOLDER: NEXT_PHASE_NAME] (sketched — activate after current phase)

- [PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME] — [PLACEHOLDER: BRIEF_DESCRIPTION]
- [PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME] — [PLACEHOLDER: BRIEF_DESCRIPTION]

---

## Decision Pending

<!-- Aging proposals that have NOT been killed, scheduled, or re-deferred. Each row needs an
     owner and a since-date. If a row sits here longer than 30 days, force a decision or kill it.
     If empty, write "_No pending decisions._" — do not delete this section.
     When a row is resolved, MOVE the decision into ROADMAP.md's Decision Log with the rationale,
     then remove it from this table. This Pilot tracks open decisions; ROADMAP.md is the audit
     trail of resolved ones. -->


| Decision | Owner | Since | Next step |
|----------|-------|-------|-----------|
| [PLACEHOLDER: PROPOSAL] | [PLACEHOLDER: NAME] | [PLACEHOLDER: DATE] | [PLACEHOLDER: NEXT_STEP_OR_KILL_DATE] |

---

## Recent Shipped (since [PLACEHOLDER: DATE])

<!-- Regenerate this section before any session-start or Pilot review. The single source of truth
     is the git log; restating it here gives an agent reading the Pilot a coverage anchor.

     Regenerate command (run from repo root, replace YYYY-MM-DD with the date in the heading):
       git log --oneline --since=YYYY-MM-DD -- [PLACEHOLDER: NAMED_DIRS_OR_DOT]

     Update the heading date and the `Last commit captured` header field whenever you regenerate. -->

- [PLACEHOLDER: SHORT_HASH] [PLACEHOLDER: ONE_LINE_SUMMARY]
- [PLACEHOLDER: SHORT_HASH] [PLACEHOLDER: ONE_LINE_SUMMARY]

---

## Phase Transitions

<!-- ONLY the next transition. Full transition tables belong in ROADMAP.md.
     Trigger must be data-driven (a metric threshold, a user count, a deployment), not a date. -->

| Transition | Trigger |
|-----------|---------|
| [PLACEHOLDER: CURRENT_PHASE] → [PLACEHOLDER: NEXT_PHASE] | [PLACEHOLDER: DATA_DRIVEN_TRIGGER] |

---

## Metrics Snapshot

<!-- 3-5 metrics typical. Category column ties each metric to an AARRR family so you can see
     at a glance which families are unmonitored. Full definitions live in METRICS_AND_OKRS.md. -->

| Metric | Category | Target | Current |
|--------|----------|--------|---------|
| [PLACEHOLDER: METRIC_1] | [PLACEHOLDER: AARRR — Acquisition / Activation / Engagement / Retention / Revenue] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |
| [PLACEHOLDER: METRIC_2] | [PLACEHOLDER: AARRR] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |
| [PLACEHOLDER: METRIC_3] | [PLACEHOLDER: AARRR] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |

---

## Open Tooling Gaps

<!-- Known limitations of the harness or enforcement layer that this Pilot CANNOT fix on its own.
     Use this section to flag where doc-only rules are pretending to be enforced. If empty,
     write "_No known gaps._" — do not delete this section. -->

- [PLACEHOLDER: GAP_DESCRIPTION — e.g., "No pre-commit hook enforces session-end doc updates; this Pilot relies on agent compliance."]

---

## Product Docs Index

<!-- Lite scope: list only the 3 generated docs (PRODUCT_OVERVIEW, FEATURE_INVENTORY, ROADMAP). -->
<!-- Micro scope: omit this entire section. -->
<!-- The "Last reviewed" column reads each doc's <!-- Last reviewed: --> header comment. Review
     cadence without per-doc timestamps is meaningless — both columns are required. -->

| File | What's in it | Review cadence | Last reviewed |
|------|-------------|----------------|---------------|
| `PRODUCT_OVERVIEW.md` | Vision, mission, principles, target users | Quarterly | [PLACEHOLDER: DATE] |
| `FEATURE_INVENTORY.md` | Shipped + planned features with lightweight PRDs | After each feature ships | [PLACEHOLDER: DATE] |
| `ROADMAP.md` | Phased roadmap with milestones and prioritization | Monthly | [PLACEHOLDER: DATE] |
| `METRICS_AND_OKRS.md` | Metric definitions, OKRs, review templates | Weekly (metrics), Quarterly (OKRs) | [PLACEHOLDER: DATE] |
| `USER_RESEARCH.md` | User segments, personas, hypotheses to validate | After each research cycle | [PLACEHOLDER: DATE] |
| `COMPETITIVE_LANDSCAPE.md` | Competitor analysis with feature matrix and positioning | Quarterly | [PLACEHOLDER: DATE] |

---

## Changelog

<!-- Append-only log of structural changes to THIS Pilot. Format: YYYY-MM-DD — what changed.
     Routine content edits (milestone tick-offs, metric updates) do NOT belong here — only
     structural changes (sections added/removed/reordered, format-version bumps). -->

- [PLACEHOLDER: DATE] — Initial Pilot generated (format version 2.2)
