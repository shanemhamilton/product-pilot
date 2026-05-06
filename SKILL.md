---
name: product-pilot
description: >
  Product Pilot — the AI-agent product context system. Use in three situations:
  (1) Session start — when loading product context before beginning work ("what should I work on",
  "what's the current milestone", "read the product pilot", "catch me up on where we are",
  "what phase are we in", "what's blocking us");
  (2) Setup — when a project has no product docs yet ("set up product pilot", "create product
  context", "bootstrap product docs", "make my agent product-aware");
  (3) Update — when a milestone completes or phase shifts ("update the pilot", "milestone done",
  "we moved to the next phase", "log what we shipped"). When in doubt, trigger this skill — it
  detects the right mode automatically based on what exists in the project.
---

# Product Pilot — Setup Skill

<!-- Source: https://github.com/shanemhamilton/product-pilot -->
<!-- Product Pilot package version: 2.3 -->

This skill creates and maintains a Product Pilot — a standalone file that gives AI coding agents product awareness: what phase you're in, what milestone is active, what's blocking ship, what metrics matter, what just shipped, what decisions are pending, and what docs to update when done.

**Honest scope note:** This skill does not enforce session-start reads or session-end doc updates — those are the agent's voluntary responsibility. See `TOOLING_GAPS.md` for the harness gaps and what tenants can do to close them.

---

## Mode Detection

Before doing anything, determine which mode to run:

| Signal | Mode | What you'll do |
|--------|------|---------------|
| Pilot exists AND user wants context / is starting a session | **Context** | Read pilot → produce brief orientation |
| Pilot exists AND user mentions changes, completion, or updates | **Update** | Ask what changed → update relevant docs |
| No pilot anywhere in the project | **Setup** | Interview → generate docs |
| User explicitly says "set up" or "bootstrap" | **Setup** | Interview → generate docs (even if pilot exists) |

**Context mode is the most common.** When the pilot exists and the user says "start of session" or asks what to work on, run Context mode — not Setup, not Update.

---

## Context Mode (session start — fastest path)

Run when `PRODUCT_PILOT.md` exists and no setup or update is requested.

If there is no pilot yet, fall through to **Setup mode** instead.

### Step 1: Read and locate
Read `PRODUCT_PILOT.md`. Find the `← ACTIVE` or `<- ACTIVE` milestone.

### Step 2: Synthesize a brief orientation
Report (under 150 words):
- **Phase** — current phase name and goal
- **Active milestone** — name, unchecked `[ ]` tasks, completion signal
- **Top blocker** — from the bulletized "What's Blocking Ship" section (name the blocker, what unblocks it, owner)
- **Recent shipped count** — number of items in the Recent Shipped section since its heading date
- **Metrics at risk** — any metric where Current is significantly below Target (flag these; skip metrics that are "Pre-launch")
- **Pending decisions** — count of rows in Decision Pending; flag any older than 30 days

### Step 3: Freshness checks (run in order, stop at first applicable)
1. Compare `<!-- Last commit captured: HASH -->` against `git rev-parse --short HEAD`. If they differ by more than 10 commits → flag: "The Pilot's last commit anchor is X commits behind HEAD — Recent Shipped is stale. Run the regenerate command before proceeding."
2. If `<!-- Last updated: -->` is more than 30 days old → flag: "The Pilot is X days stale — consider a review after this session."
3. If every task in `← ACTIVE` is checked `[x]` → prompt: "Milestone [X] looks complete. Should we advance `← ACTIVE` to the next milestone?"
4. If PRODUCT_PILOT.md is over 140 lines → note: "The Pilot has grown past 140 lines — operational detail may need moving to a supporting doc."
5. If the Product Docs Index has any `Last reviewed` date more than 30 days old → flag: "[DOC] hasn't been reviewed in over 30 days. Consider updating it this session or scheduling a review."

### Step 4: Connect to current task
If the user's task aligns with the active milestone, say so. If it diverges, note the divergence briefly and offer to log it at session end via Update mode.

**That's it.** No questions, no doc generation. Switch to Update mode if the user wants to log changes.

---

## Update Mode

If a `PRODUCT_PILOT.md` file exists anywhere in the project (check `{PRODUCT_DOCS}`, or search for it), run this section. Use its location as `{PRODUCT_DOCS}`.

**Shortcut:** If this is a periodic review with no specific changes → skip to the Periodic Review checklist at the bottom of this section.

### What changed? (ask the user)

1. Did you complete any milestones or tasks since the last update?
2. Are you moving to a new phase, or staying in the current one?
3. Do you have updated metric values (actual numbers replacing Pre-launch / TBD)?
4. New milestones, features, or priorities to add?
5. Anything new in the competitive landscape?

If nothing changed and the user wants a periodic review → skip to the Periodic Review checklist below.

### What to update

| Change type | Files to update | What to do |
|-------------|----------------|------------|
| Milestone completed | PRODUCT_PILOT.md + ROADMAP.md | Check off items, advance `← ACTIVE` to next milestone. In PRODUCT_PILOT.md, move the completed milestone summary into the Recent Shipped section if Pilot length is above 140 — full detail lives in ROADMAP.md. |
| Phase transition | PRODUCT_PILOT.md + ROADMAP.md | Move `← ACTIVE` to first milestone of new phase, update "Current phase" and the next-transition row |
| Metrics refresh | PRODUCT_PILOT.md + METRICS_AND_OKRS.md | Replace Pre-launch/TBD with actual values in both files; verify both agree |
| New milestone | ROADMAP.md first, then PRODUCT_PILOT.md | Add to correct phase with checklist + completion signal |
| Competitive update | COMPETITIVE_LANDSCAPE.md | Add/update competitor entry; refresh differentiator if positioning shifted |
| Feature shipped | FEATURE_INVENTORY.md + Pilot Recent Shipped | Add feature card with status, problem, solution, key metric; add a short_hash + one-line summary to Recent Shipped |
| New blocker / unblock | PRODUCT_PILOT.md | Update "What's Blocking Ship" — bulletized only, never prose paragraphs. Each blocker needs unblock condition, owner, since-date |
| Aging proposal | PRODUCT_PILOT.md | Add row to Decision Pending with owner + since-date. If a row sits there >30 days, force a kill or schedule decision |
| Harness limitation found | PRODUCT_PILOT.md Open Tooling Gaps | Acknowledge enforcement gaps explicitly rather than silently relying on agent compliance |
| Pilot over 140 lines | PRODUCT_PILOT.md | Move operational detail (commit hashes inside milestones, sub-task tracking, full transition tables) to supporting docs |

Always update `<!-- Last updated: -->` AND `<!-- Last commit captured: -->` in the Pilot header whenever you edit it. Update `<!-- Last reviewed: -->` in any sister doc you modify, and reflect the new date in the Pilot's Product Docs Index `Last reviewed` column.

### Expanding Scope

If supporting docs are missing and you want to add them (e.g., upgrading from Micro to Lite or Full):

1. Check which docs from the Step 4 table are missing in `{PRODUCT_DOCS}`
2. Run the relevant interview questions for the missing docs (see scope table at top)
3. Generate only the missing docs using Step 4
4. Update the Product Docs Index in PRODUCT_PILOT.md to include the new docs

### Periodic Review (monthly, or when Last reviewed >30 days old)

- [ ] PRODUCT_OVERVIEW.md: Product description still accurate? Principles shifted?
- [ ] COMPETITIVE_LANDSCAPE.md: New entrants, pivots, or pricing changes?
- [ ] METRICS_AND_OKRS.md: Set new quarterly OKRs; retire stale metrics
- [ ] ROADMAP.md: Re-evaluate upcoming items; remove items no longer relevant
- [ ] All files: Update `<!-- Last reviewed: -->` dates

---

## Setup Mode

Run when no `PRODUCT_PILOT.md` exists, or when the user explicitly requests setup.

**`{PRODUCT_DOCS}` convention:** This skill uses `{PRODUCT_DOCS}` as a variable for the product docs directory path. Step 0 resolves this to an actual path (e.g., `docs/product/`). Substitute the resolved path everywhere you see `{PRODUCT_DOCS}`.

**Output format:** All generated files are markdown (`.md`) — structured, parseable, and readable by both humans and machines.

**Choose scope after Step 0 (not before).** Run the pre-setup audit first, then recommend a scope based on what you find:

| What Step 0 found | Recommended scope |
|-------------------|------------------|
| No product docs, greenfield project | **Micro** (start small) or **Full** (if user has clear product context) |
| README + code, no product docs | **Lite** (extract from README, generate 3 core docs) |
| Some supporting docs exist | **Full** (fill gaps, synthesize into Pilot) |
| Full supporting docs, no Pilot | **Pilot-only** (skip Step 4 entirely — just generate PRODUCT_PILOT.md) |

Present your recommendation with reasoning: "Based on what I found, I'd recommend [scope] because [reason]. Want Full, Lite, or Micro instead?" Default to **Full** if the user has clear product context and wants everything.

| Scope | What you get | Interview Qs | Time |
|-------|-------------|--------------|------|
| **Full** | Product Pilot + 6 supporting docs + reference block | All 12 | 15-20 min |
| **Lite** | Product Pilot + PRODUCT_OVERVIEW + FEATURE_INVENTORY + ROADMAP + reference block | Q1-Q10 | 10-15 min |
| **Micro** | Product Pilot + reference block only | Q1-Q8 | 5-10 min |

---

## Step 0: Pre-Setup Audit

Before starting, assess what exists. Run these checks:

### Resolve `{PRODUCT_DOCS}` path

Find where product docs should live. Check in this order:

1. **Existing product docs directory** — Search for `PRODUCT_PILOT.md`, `PRODUCT_OVERVIEW.md`, `ROADMAP.md`, or similar product docs anywhere in the project. If found, use their parent directory.
2. **Existing docs directory** — Look for `docs/`, `documentation/`, `doc/`, or similar top-level documentation directories. If one exists, use `{existing_docs_dir}/product/` (e.g., `documentation/product/`).
3. **Default** — If no docs directory exists, use `docs/product/`.

Once resolved, use this path as `{PRODUCT_DOCS}` for the rest of the setup. Tell the user: "I'll put product docs in `{resolved_path}` — does that work?"

### Check the project structure

```
- Does `{PRODUCT_DOCS}` exist? If yes, check what's already there.
- Does an agent instruction file exist? Look for: CLAUDE.md, AGENTS.md, .cursorrules,
  .cursor/rules, or a system prompt file.
- Does a README exist? It often contains product context to extract.
- Is there a git history? Recent commits reveal what the team is working on.
- Are there existing product docs (PRDs, roadmaps, OKRs) anywhere in the repo?
```

### Determine starting point

| What exists | Approach |
|-------------|----------|
| Nothing — greenfield project | Full setup: interview + generate all docs from scratch (count depends on scope) |
| README + code, no product docs | Audit-first: extract context from README and code, then fill gaps via interview |
| Some product docs exist | Gap analysis: check which of the 6 supporting docs exist, create missing ones, build Product Pilot on top |
| Full product docs, no Product Pilot | Pilot-only: synthesize existing docs into a PRODUCT_PILOT.md + add agent instruction reference |
| User doesn't know metrics | Use phase-based suggestions from Q6 table; approximate targets are better than none |
| Multiple active workstreams | Pick ONE as the active milestone; consider if they should be sequential milestones |
| All metrics are "pre-launch" | Set targets now; the agent fills in actual values post-launch |
| CLAUDE.md has embedded product info | Move it into the Pilot and supporting docs; the reference block replaces it |
| Not ready for all 6 supporting docs | Start with at least 3: PRODUCT_OVERVIEW, FEATURE_INVENTORY, ROADMAP; update the Pilot index accordingly |

---

## Step 0.5: Pre-fill Pass

Before asking questions, use Step 0 findings to pre-fill answers. For each question, check the source. If the answer is unambiguous → HIGH confidence: present it with "I found this — does it look right?" If partial/ambiguous → MEDIUM: present and ask for corrections. If no source → LOW: ask open-ended.

Sources depend on the starting point from Step 0. Greenfield projects will default to LOW for most questions since no docs exist yet. Never reference a file that hasn't been created yet — only use sources that exist in the repo.

| Q | Infer from | HIGH confidence when |
|---|------------|---------------------|
| Q1 | README, PRODUCT_OVERVIEW.md (if exists) | Clear 2-3 sentence description exists |
| Q2 | README, USER_RESEARCH.md (if exists) | Named segments with pain points |
| Q3 | ROADMAP.md `← ACTIVE`, git recency | Phase label + milestones exist |
| Q4 | ROADMAP.md active milestone unchecked tasks | Incomplete tasks clearly stated |
| Q5 | PRODUCT_OVERVIEW.md principles section | 3+ named principles listed |
| Q6-Q7 | METRICS_AND_OKRS.md, PRODUCT_PILOT.md snapshot | 5 metrics with numeric targets |
| Q8 | ROADMAP.md active phase milestones | Milestones with checklists exist |
| Q9 | ROADMAP.md next phase section | 2+ milestones sketched |
| Q10 | ROADMAP.md exit criteria, PRODUCT_PILOT.md transitions | Data-driven trigger sentence exists |
| Q11-Q12 | COMPETITIVE_LANDSCAPE.md | 2+ competitors with strengths/weaknesses |

Present all HIGH answers together first for bulk confirmation. Then work through MEDIUM answers one at a time. Then ask LOW questions open-ended.

---

## Step 1: Project Orientation Interview

Ask only questions not resolved as HIGH confidence in the Pre-fill Pass. For MEDIUM answers, present the pre-filled value and ask for corrections. For HIGH answers already confirmed, skip entirely.

### Questions to ask

**Q1: What is your product?**
Get a 2-3 sentence description. What does it do? Who is it for? What makes it different?

**Q2: Who are your target users?**
Get 2-3 user segments. For each: who they are, their main pain point, what they need.

**Q3: What phase are you in?**
Present these options and ask the user to pick:

| Phase | Description | Typical signals |
|-------|-------------|-----------------|
| **Ideation** | Exploring the problem space | No code yet, researching users |
| **MVP** | Building the minimum viable product | Core features in development |
| **Launch** | Getting to market | Product built, preparing for release |
| **Validate** | Proving product-market fit | Live with users, watching metrics |
| **Monetize** | Generating revenue | Adding pricing, payments, conversion |
| **Grow** | Scaling users and revenue | Acquisition channels, engagement features |
| **Mature** | Optimizing and expanding | Platform expansion, new markets |

**Q4: What's blocking you right now?**
Get the single biggest blocker or next thing that needs to happen.

**Q5: What are your core product principles?**
What 3-5 rules guide every product decision? If the user isn't sure, suggest from common patterns:

| Principle | Meaning |
|-----------|---------|
| Privacy first | Never share or sell user data; minimize collection |
| Speed over features | A fast, simple tool beats a slow, feature-rich one |
| Data-driven | Decisions backed by metrics, not opinions |
| Accessibility by default | Works for all users, not just power users |
| Transparency | Show users how/why decisions are made, not just the result |
| Opinionated defaults | Make the right choice easy; don't overwhelm with options |

---

## Step 2: Metrics & Milestones Interview

### Metrics questions

**Q6: What are your top 5 metrics?**
If the user isn't sure, suggest a standard set based on their phase:

| Phase | Suggested metrics |
|-------|-------------------|
| MVP / Launch | DAU, first-action rate, core action completion, D7 retention, crash-free rate |
| Validate | D7 retention, D30 retention, activation rate, core loop frequency, NPS/CSAT |
| Monetize | Trial starts, free-to-paid conversion, MRR, churn rate, LTV |
| Grow | MAU growth rate, organic %, referral rate, CAC, engagement depth |

**Q7: What are your targets for each metric?**
Get a target number for each. If pre-launch, note "Pre-launch" as the current value.

### Milestone questions

**Q8: For your current phase, what are the 2-4 things that need to happen (in order)?**
These become milestones. Each milestone should be completable in 1-3 work sessions.

For each milestone, ask:
- What specific tasks need to be done? (These become the checklist items)
- How will you know it's done? (This becomes the completion signal)
- Does it depend on a previous milestone? (This becomes the dependency)

**Q9: What comes after this phase?**
Sketch the next 1-2 phases with rough milestones. These don't need to be detailed yet.

**Q10: What triggers moving to the next phase?**
Get a data-driven condition, not a date. Examples: "App live on App Store,"
"D7 retention above 25%," "First paying customer."

### Good vs Bad Examples

| Element | Bad | Good |
|---------|-----|------|
| Phase trigger | "End of Q2" / "When we feel ready" | "D7 retention >25% AND 100+ active users" |
| Completion signal | "Feature is done" / "Looks good" | "Zero P0 bugs for 48 hours after deploy" |
| Milestone scope | "Build the app" (too large) | "Stripe integration passing end-to-end test" (1-3 sessions) |

---

## Step 3: Competitive Context (Quick)

**Q11: Who are your top 2-3 competitors or alternatives?**
For each: what they do, their key strength, their key weakness.

**Q12: What's your key differentiator?**
One sentence: why would someone choose your product over the alternatives?

---

## Interview Edge Cases

| Situation | How to handle |
|-----------|---------------|
| 0 competitors | Ask about alternatives (spreadsheets, manual processes, "doing nothing"). Every product competes with the status quo. |
| Only 1 metric | Accept it. Use phase-based suggestions from Q6 to propose 2-4 more, but don't force 5. |
| >4 milestones in current phase | Split into sub-phases or sequence into next phase. Each phase should have 2-4 milestones max. |
| Only 1 milestone | Acceptable for Micro scope. For Full/Lite, probe for hidden dependencies ("what has to be true before that milestone is done?"). |
| User gives date-based triggers | Reframe: "What metric or outcome would that date achieve?" Convert to data-driven triggers. |
| Vague completion signals | Push for observable signals: deployments, metric thresholds, user counts, passing tests — not feelings. |

---

## Step 4: Generate the 6 Supporting Documents

Create `{PRODUCT_DOCS}` if it doesn't exist. Read each template only when generating that specific document. For each:

1. Read the template from this skill's `templates/` directory
2. Fill in all `[PLACEHOLDER: ...]` markers using the interview answers from Steps 1-3
3. For any placeholders you can't fill from the interview, make reasonable inferences
   from the codebase (README, code structure, git history) or convert to a `[TODO: ...]` marker
4. Save to `{PRODUCT_DOCS}`

**Important:** All `[PLACEHOLDER: ...]` markers must be either replaced with real content or converted to `[TODO: ...]`. The only marker allowed in final output is `[TODO: ...]`. No `[PLACEHOLDER: ...]` should survive into the generated docs.

**Scope adjustments:**
- **Full:** Generate all 6 supporting docs
- **Lite:** Generate only PRODUCT_OVERVIEW, FEATURE_INVENTORY, and ROADMAP (skip the other 3)
- **Micro:** Skip Step 4 entirely — go straight to Step 5

### Documents to generate (independent — any order, parallelizable)

| File | Template | Primary source | Target length |
|------|----------|----------------|---------------|
| `PRODUCT_OVERVIEW.md` | `templates/PRODUCT_OVERVIEW_TEMPLATE.md` | Q1, Q2, Q5 | ~60-80 lines |
| `FEATURE_INVENTORY.md` | `templates/FEATURE_INVENTORY_TEMPLATE.md` | Codebase audit | ~80-300 lines |
| `COMPETITIVE_LANDSCAPE.md` | `templates/COMPETITIVE_LANDSCAPE_TEMPLATE.md` | Q11, Q12 | ~60-120 lines |
| `METRICS_AND_OKRS.md` | `templates/METRICS_TEMPLATE.md` | Q6, Q7 | ~60-100 lines |
| `USER_RESEARCH.md` | `templates/USER_RESEARCH_TEMPLATE.md` | Q2 | ~80-150 lines |
| `ROADMAP.md` | `templates/ROADMAP_TEMPLATE.md` | Q3, Q4, Q8, Q9, Q10 | ~80-200 lines |

### Parallel agent mode (optional — Full scope only)

If the host supports parallel agents and the user has enabled or approved delegation, spawn 3 workers in parallel instead of generating docs sequentially. Create `{PRODUCT_DOCS}` first, then spawn:
- **Product Strategist**: PRODUCT_OVERVIEW + COMPETITIVE_LANDSCAPE (Q1, Q2, Q5, Q11, Q12)
- **Roadmap Engineer**: ROADMAP + METRICS_AND_OKRS (Q3, Q4, Q6-Q10)
- **User Researcher**: USER_RESEARCH + FEATURE_INVENTORY (Q2 + code audit)

Each worker prompt must include: full interview answers, template paths, target file paths, target lengths, and the placeholder rule. Lite scope (3 docs) rarely justifies delegation overhead — generate sequentially. After all workers complete, the lead proceeds to Step 5.

### Feature inventory from codebase

For the Feature Inventory, audit the codebase to discover features:

- Check route definitions, view controllers, or page components
- Look for API endpoints or Cloud Functions
- Review the README for feature descriptions
- Check git history for major feature additions
- Group features into logical categories

### Using PM skills (optional companions)

These PM skills are optional companions — not required. If not installed, the templates are self-sufficient. When available, they produce higher-quality output:

| Document | Skill to load |
|----------|---------------|
| `FEATURE_INVENTORY.md` | `feature-spec` |
| `ROADMAP.md` | `roadmap-management` |
| `METRICS_AND_OKRS.md` | `metrics-tracking` |
| `USER_RESEARCH.md` | `user-research-synthesis` |
| `COMPETITIVE_LANDSCAPE.md` | `competitive-analysis` |

---

## Step 5: Create PRODUCT_PILOT.md

This is the Product Pilot itself. Read `templates/PRODUCT_PILOT_TEMPLATE.md` and fill it in
by synthesizing everything from Steps 1-4.

### Question-to-section mapping

| Product Pilot section | Fill from |
|-------------|-----------|
| Quick Orientation | Q1 (description), Q3 (phase), Q4 (blocker) |
| Active Milestones | Q8 (current phase), Q9 (next phase sketched) |
| Phase Transitions | Q10 (data-driven triggers) |
| Metrics Snapshot | Q6 + Q7 (top 5 metrics with targets) |
| Agent Operating Instructions | Use template as-is |
| Product Docs Index | Use template as-is |

### Critical rules

- Keep the Pilot under 140 lines (filled). Move overflow to supporting docs.
- Mark exactly ONE milestone as `← ACTIVE`
- All phase transition triggers must be data-driven, not calendar-driven
- No `[PLACEHOLDER: ...]` markers should remain in the final file
- "What's Blocking Ship" must be bulletized — never prose. Each bullet: blocker / unblock condition / owner / since date
- Phase Transitions table shows ONLY the next transition; full transition history lives in ROADMAP.md
- Recent Shipped section has a regenerate command pinned in its HTML comment; update the heading date and `Last commit captured` header whenever you regenerate
- Decision Pending and Open Tooling Gaps are required sections — keep them present even when empty (use placeholder text like "_No pending decisions._" or "_No known gaps._"). Empty sections force tenants to surface gaps; missing sections let gaps stay invisible.
- Completed milestones can be summarized in Recent Shipped (full detail stays in ROADMAP.md as completed work)
- The Pilot should be readable in under 2 minutes
- **Lite scope:** Product Docs Index lists only the 3 generated docs (PRODUCT_OVERVIEW, FEATURE_INVENTORY, ROADMAP)
- **Micro scope:** Omit the Product Docs Index section entirely. Decision Pending, Recent Shipped, and Open Tooling Gaps remain — they are not docs-index-dependent.

---

## Step 6: Update the Agent Instruction File

Read `references/AGENT_INSTRUCTION_REFERENCE.md` for the reference block to add.

### Where to add it

| File | Placement |
|------|-----------|
| `CLAUDE.md` | After user preferences, before engineering instructions |
| `AGENTS.md` | In the main project instructions section |
| `.cursorrules` | Near the top, after project description |
| System prompt | At the beginning of project-specific instructions |

### What to add

The reference block should:
- Frame the Pilot read as the agent's responsibility (not as a harness-enforced rule — there is no enforcement layer; see `TOOLING_GAPS.md`)
- Tell the agent to read `{PRODUCT_DOCS}PRODUCT_PILOT.md` before starting work
- Tell the agent to follow the Session End checklist when done
- Reference PM skills if available
- Point to `{PRODUCT_DOCS}` for deep context

### What to remove

If the agent instruction file already contains embedded product context (product descriptions,
phase information, roadmap details, metric targets), remove it. The Pilot now owns that
information. Keeping it in both places creates drift and confusion.

---

## Verification Checklist

After completing setup or any update, run BOTH the manual checklist and the deterministic grep-checks below. Manual review alone has been observed to return all-PASS on Pilots with critical defects (e.g., a gitignored docs directory). The grep-checks are the mandatory final gate.

### Content quality

- [ ] No `[PLACEHOLDER: ...]` markers remain in any file
- [ ] Product Pilot has all required sections (Quick Orientation, Agent Operating Instructions, Active Milestones, Decision Pending, Recent Shipped, Phase Transitions, Metrics Snapshot, Open Tooling Gaps, Product Docs Index, Changelog)
- [ ] Exactly ONE milestone is marked `← ACTIVE`
- [ ] All phase transition triggers are data-driven, not calendar-driven
- [ ] Metrics have Target, Current, AND Category columns
- [ ] Agent instruction file has the Product Pilot reference block
- [ ] No duplicate product context in agent instruction file

### Cross-references

- [ ] Product Pilot references all 6 supporting docs by correct filename (Full scope)
- [ ] ROADMAP milestones match Product Pilot milestones (no contradictions)
- [ ] Metrics in Product Pilot snapshot match METRICS_AND_OKRS definitions (target AND current)
- [ ] FEATURE_INVENTORY categories match codebase reality
- [ ] `Last reviewed` dates in the Pilot's Product Docs Index match the `<!-- Last reviewed: -->` headers in each sister doc

### Pilot Health Check

- [ ] PRODUCT_PILOT.md is 140 lines or fewer (filled tenant Pilots)
- [ ] "What's Blocking Ship" is bulletized — one bullet per blocker with unblock condition, owner, since date. Prose paragraphs are a structural defect.
- [ ] No milestone has more than 10 tasks — if so, split into sub-milestones
- [ ] No `← ACTIVE` milestone has all tasks checked (if all done, advance to next milestone)
- [ ] Recent Shipped section heading date matches the regenerate command's `--since=` value
- [ ] `Last commit captured` header matches a real commit and is within 10 commits of HEAD
- [ ] Decision Pending and Open Tooling Gaps sections exist (even if empty with placeholder text)

### Mandatory grep-check gate

Run the deterministic grep-checks defined in `references/AUDIT_PROMPT_PACK.md` (section "Verification grep-checks"). They cover:

1. Product docs directory must NOT be gitignored
2. No `[PLACEHOLDER:]` markers survive
3. Exactly one `← ACTIVE` marker
4. `Last commit captured` references a real commit
5. All required sections present
6. Pilot under 140 lines

Two prior verifier agents returning all-PASS does not substitute for these. If the grep-checks pass and a verifier returned all-PASS, run the **Challenge-all-positive gate** from the audit pack — verifier sycophancy is a known failure mode.

### Optional but recommended: 5-angle audit

For a complete review (especially before milestone advancement or phase transition), run all five angles from `references/AUDIT_PROMPT_PACK.md`: drift, coverage, structure, sister-doc consistency, session compliance. Each angle has its own prompt with anti-sycophancy quotas baked in.

---

## Output Standards

These rules apply whenever this skill generates content or reviews product state. They exist because the common failure modes in product doc work are sycophantic reviews and fabricated data — both of which produce documents that look good but actively mislead agents.

**When reviewing milestone completeness or running a Periodic Review:**
- Lead with what's stale, blocked, or below target — not with what's done
- Check the completion signal criteria explicitly; "looks done" is not an assessment
- Name issues specifically: "D7 retention at 18% vs 30% target" not "retention needs work"
- A Periodic Review that finds nothing wrong is a sign you didn't look hard enough

**When generating or updating product docs:**
- Never invent metric targets — only use values the user provides; mark gaps as `[TODO: add target]`
- Never fabricate competitor data, pricing, or feature comparisons — mark as `[TODO: research]`
- Never invent commit hashes for `Last commit captured` or Recent Shipped entries — derive them from `git log` or `git rev-parse`
- No `[PLACEHOLDER: ...]` marker may survive into final files — replace with real content or convert to `[TODO: ...]`
- Don't infer completion signals from milestone names — ask if the user hasn't specified one
- Don't round or approximate numbers: "28% retention" not "~30%"

**When acknowledging gaps:**
- Open Tooling Gaps must reflect the host harness honestly. If session-start reads are not enforced by a hook, the Pilot must say so. Never describe an unenforced rule as "mandatory."
- If the host repo's `.gitignore` excludes the product docs directory, flag it as a critical gap — the Pilot is not version-controlled and every claim of audit/tracking is hollow.

---

## Patterns Worth Adopting

These patterns emerged from real-world Product Pilot deployments and produce better results:

- **Assumption validation tables** — In USER_RESEARCH.md, track assumptions as structured rows (Assumption / Validation method / Status) instead of freeform checklists. This makes it clear what's been tested, what hasn't, and how.
- **Observable completion signals** — Every milestone should have a signal you can verify without subjectivity: a passing test, a metric threshold, a deployment, a user count. "Feels ready" is never a completion signal.
- **RICE as default prioritization** — When the user has no preference, default to RICE (Reach, Impact, Confidence, Effort). It's simple, widely understood, and forces numeric thinking.
- **Decision Log as living record** — The Decision Log in ROADMAP.md should be updated whenever priorities shift, not just at setup time. It becomes the project's institutional memory.

---

## Example: Filled-in Product Pilot (v2.2 structure, fictional product)

The excerpt below shows the v2.2 sections in use. Section ordering and field formats are normative; the content is illustrative.

> ```
> <!-- Product Pilot format version: 2.2 -->
> <!-- Pilot scope: Full -->
> <!-- Last updated: 2026-04-28 -->
> <!-- Last commit captured: a3f9c12 -->
> <!-- Owner: Priya R. -->
> ```
>
> ## Quick Orientation
>
> **TaskFlow** is a collaborative task management app for small teams (3-15 people) that emphasizes async work and clear ownership.
>
> **Current phase:** 1 — Validate
>
> ### What's Blocking Ship
>
> - **Trial conversion below threshold** — Unblocked when: trial-to-paid >15% across 50+ trial starts. Owner: Priya. Since: 2026-04-10
> - **Pricing model undecided** — Unblocked when: A/B test on trial length completes. Owner: Marcus. Since: 2026-04-15
>
> ## Agent Operating Instructions
>
> _(see template — used as-is)_
>
> ## Active Milestones
>
> ### Phase 1: Validate
>
> - **[1.3] Pricing Model & Trial Optimization** ← ACTIVE
>   - [ ] Run 3-week A/B test on trial length (7d vs 14d)
>   - [ ] Collect 50+ trial starts and measure conversion
>   - Completion signal: Trial-to-paid conversion >15%
>
> ## Decision Pending
>
> | Decision | Owner | Since | Next step |
> |----------|-------|-------|-----------|
> | Annual vs monthly pricing default | Marcus | 2026-04-12 | Decide by 2026-05-15 or kill |
>
> ## Recent Shipped (since 2026-04-15)
>
> - a3f9c12 Wire trial-length variant flag into onboarding
> - 882ee0d Add trial-conversion analytics events
>
> ## Phase Transitions
>
> | Transition | Trigger |
> |-----------|---------|
> | Phase 1 → 2 | D7 retention >30% AND trial-to-paid >15% |
>
> ## Metrics Snapshot
>
> | Metric | Category | Target | Current |
> |--------|----------|--------|---------|
> | D7 retention | Retention | >30% | 28% |
> | Trial-to-paid conversion | Revenue | >15% | 12% |
> | Task completion rate | Engagement | >2.5/user/day | 1.8 |
>
> ## Open Tooling Gaps
>
> - No pre-commit hook enforces session-end doc updates; this Pilot relies on agent compliance.
>
> ## Product Docs Index
>
> | File | What's in it | Review cadence | Last reviewed |
> |------|-------------|----------------|---------------|
> | `ROADMAP.md` | Phased roadmap | Monthly | 2026-04-20 |
> | `METRICS_AND_OKRS.md` | Metric definitions | Weekly | 2026-04-26 |
>
> ## Changelog
>
> - 2026-04-28 — Bumped to format version 2.2; added Decision Pending, Recent Shipped, Open Tooling Gaps
