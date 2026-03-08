# Product Pilot

<!-- MANDATORY: Read this file at the start of every session. -->
<!-- Product Pilot format version: 2.0 -->
<!-- Last updated: [PLACEHOLDER: DATE] -->
<!-- Owner: [PLACEHOLDER: OWNER_NAME] -->

## Quick Orientation

[PLACEHOLDER: PRODUCT_DESCRIPTION — 2-3 sentences describing what the product does and who it's for]

**Current phase:** [PLACEHOLDER: PHASE_NUMBER] — [PLACEHOLDER: PHASE_NAME]
**What's blocking:** [PLACEHOLDER: TOP_BLOCKER — what must happen next]
**Deep context:** See the supporting docs indexed at the bottom of this file.

---

## Active Milestones

### [PLACEHOLDER: PHASE_NAME]

<!-- 2-4 milestones typical. Delete unused blocks. -->
- **[PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME]** ← ACTIVE
  - [ ] [PLACEHOLDER: TASK_1]
  - [ ] [PLACEHOLDER: TASK_2]
  - Completion signal: [PLACEHOLDER: HOW_TO_KNOW_ITS_DONE]

- **[PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME]**
  - [ ] [PLACEHOLDER: TASK_1]
  - [ ] [PLACEHOLDER: TASK_2]
  - Completion signal: [PLACEHOLDER: HOW_TO_KNOW_ITS_DONE]
  - Dependency: [PLACEHOLDER: UPSTREAM_MILESTONE]

- **[PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME]**
  - [ ] [PLACEHOLDER: TASK_1]
  - Completion signal: [PLACEHOLDER: HOW_TO_KNOW_ITS_DONE]
  - Dependency: [PLACEHOLDER: UPSTREAM_MILESTONE]

### [PLACEHOLDER: NEXT_PHASE_NAME] (sketched — activate after current phase)

- [PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME] — [PLACEHOLDER: BRIEF_DESCRIPTION]
- [PLACEHOLDER: MILESTONE_ID] [PLACEHOLDER: MILESTONE_NAME] — [PLACEHOLDER: BRIEF_DESCRIPTION]

---

## Phase Transitions

Move to the next phase only when its trigger is met. These are data-driven, not calendar-driven.

<!-- Include only relevant transitions. 2-4 rows typical. Delete unused rows. -->

| Transition | Trigger |
|-----------|---------|
| [PLACEHOLDER: PHASE_A] → [PLACEHOLDER: PHASE_B] | [PLACEHOLDER: DATA_DRIVEN_TRIGGER] |
| [PLACEHOLDER: PHASE_B] → [PLACEHOLDER: PHASE_C] | [PLACEHOLDER: DATA_DRIVEN_TRIGGER] |
| [PLACEHOLDER: PHASE_C] → [PLACEHOLDER: PHASE_D] | [PLACEHOLDER: DATA_DRIVEN_TRIGGER] |

---

## Metrics Snapshot

Top metrics to optimize for (full definitions in `METRICS_AND_OKRS.md` if it exists):

<!-- 3-5 metrics typical. Delete unused rows. -->
| Metric | Target | Current |
|--------|--------|---------|
| [PLACEHOLDER: METRIC_1] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |
| [PLACEHOLDER: METRIC_2] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |
| [PLACEHOLDER: METRIC_3] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |
| [PLACEHOLDER: METRIC_4] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |
| [PLACEHOLDER: METRIC_5] | [PLACEHOLDER: TARGET] | [PLACEHOLDER: CURRENT_OR_PRE_LAUNCH] |

---

## Agent Operating Instructions

### Session Start

1. Read this Pilot file
2. Identify the `← ACTIVE` milestone
3. If your work relates to a product doc (see table below), load the relevant PM skill (if installed)
4. If the `← ACTIVE` milestone has all tasks checked off, prompt: "Milestone [X] appears complete. Should we advance `← ACTIVE` to the next milestone?"
5. If `<!-- Last updated: -->` is more than 30 days ago, prompt for a Pilot review before starting new work
6. Check the Product Docs Index below — if any doc's `<!-- Last reviewed: -->` date is more than 30 days old, flag it: "[DOC] hasn't been reviewed in over 30 days. Consider updating it this session or scheduling a review."
7. If your current task doesn't align with the `← ACTIVE` milestone, proceed with your task but note the divergence. At session end, consider whether this Pilot needs updating to reflect the actual workstream.

**Context depth by task type:**
- **Quick task** (bug fix, config change): Read only this Pilot
- **Feature work**: Read this Pilot + `FEATURE_INVENTORY.md` + `ROADMAP.md`
- **Strategic work** (new phase, pivot, major planning): Read all docs in this directory

### Session End — Update relevant docs and commit changes alongside code
Skip if your changes were trivial (typo fixes, config tweaks, non-functional changes). The checklist is for work that changes what the product does or how it's measured.

| Work type | Update this doc | Skill (if available) |
|-----------|----------------|----------------------|
| Feature shipped | `FEATURE_INVENTORY.md` | `feature-spec` |
| Milestone complete | `ROADMAP.md` + this Pilot | `roadmap-management` |
| New metric data | `METRICS_AND_OKRS.md` | `metrics-tracking` |
| User insight | `USER_RESEARCH.md` | `user-research-synthesis` |
| Competitive intel | `COMPETITIVE_LANDSCAPE.md` | `competitive-analysis` |

---

## Product Docs Index

<!-- Lite scope: list only the 3 generated docs (PRODUCT_OVERVIEW, FEATURE_INVENTORY, ROADMAP). -->
<!-- Micro scope: omit this entire section. -->

| File | What's in it | Review cadence |
|------|-------------|----------------|
| `PRODUCT_OVERVIEW.md` | Vision, mission, principles, target users | Quarterly |
| `FEATURE_INVENTORY.md` | Shipped + planned features with lightweight PRDs | After each feature ships |
| `ROADMAP.md` | Phased roadmap with milestones and prioritization | Monthly |
| `METRICS_AND_OKRS.md` | Metric definitions, OKRs, review templates | Weekly (metrics), Quarterly (OKRs) |
| `USER_RESEARCH.md` | User segments, personas, hypotheses to validate | After each research cycle |
| `COMPETITIVE_LANDSCAPE.md` | Competitor analysis with feature matrix and positioning | Quarterly |
