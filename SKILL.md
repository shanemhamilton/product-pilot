<!-- Source: https://github.com/shanemhamilton/product-pilot -->
---
name: product-pilot
description: >
  Bootstrap a Product Pilot for any project. The Product Pilot gives AI coding agents
  product awareness — what phase you're in, what to work on next, and what docs to update
  when done. Use when the user says: "set up a product pilot", "set up a product pilot",
  "create product context for my project", "bootstrap product docs", "set up product pilot",
  "make my agent product-aware", "create product management docs", or any request to establish
  product documentation that AI agents can maintain. Also use when the user asks "how do I give
  my AI agent product context" or "how do I keep my product docs up to date automatically."
version: "2.0"
---

# Product Pilot — Setup Skill

This skill walks you through creating a Product Pilot for any project.
The Product Pilot is a standalone file that gives AI coding agents product awareness — what phase
you're in, what milestone is active, what metrics matter, and what docs to update when
work is done.

**Choose your scope:**

| Scope | What you get | Interview Qs | Time |
|-------|-------------|--------------|------|
| **Full** | Product Pilot + 6 supporting docs + reference block | All 12 | 15-20 min |
| **Lite** | Product Pilot + PRODUCT_OVERVIEW + FEATURE_INVENTORY + ROADMAP + reference block | Q1-Q10 (skip Q11-Q12) | 10-15 min |
| **Micro** | Product Pilot + reference block only | Q1-Q8 (skip Q9-Q12) | 5-10 min |

Ask the user which scope they want. Default to **Full** if not specified.

**Teams mode (optional):** If Claude Code agent teams are enabled, Step 4 can spawn teammates to generate supporting docs in parallel. Each teammate owns one file — no conflicts. This cuts generation time significantly for Full scope. Teams mode is automatic when available; no user action needed beyond having teams enabled.

**`{PRODUCT_DOCS}` convention:** This skill uses `{PRODUCT_DOCS}` as a variable for the product docs directory path. Step 0 resolves this to an actual path (e.g., `docs/product/`, `documentation/product/`). When generating files or reference blocks, substitute the resolved path everywhere you see `{PRODUCT_DOCS}`.

**Output format:** All generated files are markdown (`.md`). Markdown is the optimal format for AI agents — it's structured, parseable, and readable by both humans and machines. Do not generate product docs in any other format.

---

## Update Mode (runs instead of Steps 0-6 when Product Pilot already exists)

If a `PRODUCT_PILOT.md` file exists anywhere in the project (check `{PRODUCT_DOCS}`, or search for it), skip Steps 0-6 and run this section instead. Use its location as `{PRODUCT_DOCS}`.

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
| Milestone completed | PRODUCT_PILOT.md + ROADMAP.md | Check off items, advance `← ACTIVE` to next milestone |
| Phase transition | PRODUCT_PILOT.md + ROADMAP.md | Move `← ACTIVE` to first milestone of new phase, update "Current phase" and transitions table |
| Metrics refresh | PRODUCT_PILOT.md + METRICS_AND_OKRS.md | Replace Pre-launch/TBD with actual values in both files |
| New milestone | ROADMAP.md first, then PRODUCT_PILOT.md | Add to correct phase with checklist + completion signal |
| Competitive update | COMPETITIVE_LANDSCAPE.md | Add/update competitor entry; refresh differentiator if positioning shifted |
| Feature shipped | FEATURE_INVENTORY.md | Add feature card with status, problem, solution, key metric |

Always update the date comment (`<!-- Last updated: -->` or `<!-- Last reviewed: -->`) in any file you modify.

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
- Does an agent instruction file exist? Look for: CLAUDE.md, .cursorrules, .cursor/rules,
  AGENTS.md, or a system prompt file.
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

### Teams mode: parallel generation

If agent teams are enabled, spawn teammates to generate docs in parallel instead of generating them sequentially. Create `{PRODUCT_DOCS}` first, then spawn the team.

**Team structure (Full scope — 3 teammates):**

| Teammate | Docs to generate | Why grouped |
|----------|-----------------|-------------|
| **Product Strategist** | PRODUCT_OVERVIEW + COMPETITIVE_LANDSCAPE | Both draw from product identity (Q1, Q2, Q5, Q11, Q12) |
| **Roadmap Engineer** | ROADMAP + METRICS_AND_OKRS | Both draw from milestones and metrics (Q3, Q4, Q6-Q10) |
| **User Researcher** | USER_RESEARCH + FEATURE_INVENTORY | Both draw from user segments and codebase (Q2 + code audit) |

Each teammate's prompt must include:
1. The interview answers from Steps 1-3 (all of them — teammates don't share the lead's context)
2. Which templates to read from this skill's `templates/` directory
3. The target file paths in `{PRODUCT_DOCS}`
4. The target length for each doc (from the table above)
5. The placeholder/TODO rule: replace all `[PLACEHOLDER: ...]` with real content or `[TODO: ...]`

**Lite scope (2 teammates):** Split PRODUCT_OVERVIEW to one, FEATURE_INVENTORY + ROADMAP to the other. Or just use sequential generation — 3 docs doesn't justify team overhead.

**Micro scope:** No teammates needed — skip Step 4 entirely.

After all teammates complete, the lead proceeds to Step 5 (create PRODUCT_PILOT.md) by synthesizing across all generated docs.

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

- Keep the Pilot under ~110 lines
- Mark exactly ONE milestone as `← ACTIVE`
- All phase transition triggers must be data-driven, not calendar-driven
- No `[PLACEHOLDER: ...]` markers should remain in the final file
- Completed milestones can be omitted from the Pilot (they remain in ROADMAP.md as completed work)
- The Pilot should be readable in under 2 minutes
- **Lite scope:** Product Docs Index lists only the 3 generated docs (PRODUCT_OVERVIEW, FEATURE_INVENTORY, ROADMAP)
- **Micro scope:** Omit the Product Docs Index section entirely

---

## Step 6: Update the Agent Instruction File

Read `references/CLAUDE_MD_REFERENCE.md` for the reference block to add.

### Where to add it

| File | Placement |
|------|-----------|
| `CLAUDE.md` | After user preferences, before engineering instructions |
| `.cursorrules` | Near the top, after project description |
| `AGENTS.md` | In the main instructions section |
| System prompt | At the beginning of project-specific instructions |

### What to add

The reference block should:
- Be marked MANDATORY
- Tell the agent to read `{PRODUCT_DOCS}PRODUCT_PILOT.md` before starting work
- Tell the agent to follow the session-end checklist when done
- Reference PM skills if available
- Point to `{PRODUCT_DOCS}` for deep context

### What to remove

If the agent instruction file already contains embedded product context (product descriptions,
phase information, roadmap details, metric targets), remove it. The Pilot now owns that
information. Keeping it in both places creates drift and confusion.

---

## Verification Checklist

After completing setup, verify everything:

### Content quality

- [ ] No `[PLACEHOLDER: ...]` markers remain in any file
- [ ] Product Pilot has all sections (orientation, milestones, transitions, metrics, instructions, index)
- [ ] Exactly ONE milestone is marked `← ACTIVE`
- [ ] All phase transitions have data-driven triggers (no calendar dates)
- [ ] Metrics have both Target and Current columns
- [ ] Agent instruction file has the Product Pilot reference block
- [ ] No duplicate product context in agent instruction file

### Cross-references

- [ ] Product Pilot references all 6 supporting docs by correct filename
- [ ] ROADMAP milestones match Product Pilot milestones
- [ ] Metrics in Product Pilot snapshot match METRICS_AND_OKRS definitions
- [ ] FEATURE_INVENTORY categories match codebase reality

---

## Patterns Worth Adopting

These patterns emerged from real-world Product Pilot deployments and produce better results:

- **Assumption validation tables** — In USER_RESEARCH.md, track assumptions as structured rows (Assumption / Validation method / Status) instead of freeform checklists. This makes it clear what's been tested, what hasn't, and how.
- **Observable completion signals** — Every milestone should have a signal you can verify without subjectivity: a passing test, a metric threshold, a deployment, a user count. "Feels ready" is never a completion signal.
- **RICE as default prioritization** — When the user has no preference, default to RICE (Reach, Impact, Confidence, Effort). It's simple, widely understood, and forces numeric thinking.
- **Decision Log as living record** — The Decision Log in ROADMAP.md should be updated whenever priorities shift, not just at setup time. It becomes the project's institutional memory.

---

## Example: Filled-in Product Pilot

This shows what a completed Product Pilot looks like (fictional product):

> **TaskFlow** is a collaborative task management app for small teams (3-15 people) that
> emphasizes async work and clear ownership. Users create projects, break work into tasks,
> assign to team members, and track progress without meetings.
>
> **Current phase:** 1 — Validate
> **What's blocking:** Trial conversion data → pricing model → Phase 2 launch
>
> ### Phase 1: Validate
>
> - **[1.3] Pricing Model & Trial Optimization** ← ACTIVE
>   - [ ] Run 3-week A/B test on trial length (7d vs 14d)
>   - [ ] Collect 50+ trial starts and measure conversion
>   - Completion signal: Trial-to-paid conversion >15%
>
> - **[1.4] Retention & Churn Analysis**
>   - [ ] Identify cohort with D30 retention <40%, analyze churn reasons
>   - Completion signal: D30 retention >45% in next cohort
>   - Dependency: [1.3]
>
> | Transition | Trigger |
> |-----------|---------|
> | Phase 1 → 2 | D7 retention >30% AND trial-to-paid >15% |
>
> | Metric | Target | Current |
> |--------|--------|---------|
> | D7 retention | >30% | 28% |
> | Trial-to-paid conversion | >15% | 12% |
> | Task completion rate | >2.5/user/day | 1.8 |
