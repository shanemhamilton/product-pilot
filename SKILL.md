---
name: product-pilot
description: >
  Product Pilot — product context for autonomous coding agents. Creates and maintains a
  PRODUCT_PILOT.md that holds the phase, the ACTIVE milestone with ticket-tagged tasks and a
  runnable completion Check, ship blockers, decisions with defaults and deadlines, recent ships
  from git, and runway. Use it (1) to orient at session start or before a dispatched task ("what
  should I work on", "what's blocking us from shipping", "what phase are we in", "read the
  pilot"); (2) when the work queue is empty and the next tickets must come from the roadmap
  ("we're out of tickets, what's next", "nothing ready", "pour the milestone"); (3) after merges
  or releases ("we shipped it, update the plan", "milestone done", "log what we shipped",
  "reconcile the pilot"); (4) when a project has no Pilot ("set up a product pilot", "make my
  agent product-aware"); (5) when direction changed and the roadmap must be replanned. When in
  doubt, trigger it; it detects the mode from what exists.
---

# Product Pilot

<!-- Source: https://github.com/shanemhamilton/product-pilot -->
<!-- Product Pilot package version: 3.0 -->

One file per product, under 140 lines, that an agent reads before acting and a script keeps true. It exists so an agent pipeline can run for days: the queue refills from the roadmap, milestones advance on evidence, routine decisions resolve by default, and a human is asked only for what only a human can supply.

The scripts in `scripts/` do the deterministic work. `pilot-banner.sh` prints the orientation. `pilot-grep-checks.sh` enforces the file contract in hooks and CI. `pilot-reconcile.sh` regenerates the machine sections, runs the Checks, and advances the ACTIVE milestone. `pilot-pour.sh` turns `[unpoured]` tasks into tracker tickets. `selftest.sh` proves the four work. Install them by copying or symlinking `scripts/` into the host repo; `references/AGENT_INSTRUCTION_REFERENCE.md` has the hook, CI, and dispatcher wiring.

---

## Operating Principles

Read these before any mode. They decide what the skill asks for and what it refuses to add.

1. **Zero-to-one first.** Until the product has external users, the skill asks for three things only: what ships next, what blocks shipping, and where it deploys. User interviews, surveys, personas, competitor matrices, OKRs, and quarterly reviews are opt-in workstreams that unlock at Traction or later, and only when the human asks for them. The skill never adds them on its own, never makes them milestone tasks, and never makes them phase triggers.
2. **Agents research; humans decide only what only humans can.** Setup and replanning read the repo, the tracker, the store listing, and the web when tools exist. They do not interview the human. Whatever no source answers is written as `[TODO: …]`. A `[TODO]` never blocks work.
3. **Gates stop releases, never the queue.** A ship blocker, a pending human decision, or an unmet phase trigger holds the one thing it names. Work on the next task continues. A Pilot that pauses engineering on a research outcome is a defect.
4. **Evidence over claims.** Recent Shipped comes from `git log`. Milestone completion comes from a `Check` command that exits 0. Metric values come from a `Source` command or stay `[TODO]`. Commit hashes come from git. Nothing in the file is written from memory.
5. **Decide and record.** Routine product choices belong to the agent: choose, write one line in the task or the Decision Log, continue. If a decision-authority skill such as `decision-compass` is installed, follow it. A Decision Pending row is for a choice that must wait, and it carries a Tier (`agent` or `human`), a Default, and a Deadline. Agent-tier rows resolve to their Default at the Deadline.
6. **One owner, by PR.** A named persona owns Pilot edits and lands them by pull request. Workers never edit the Pilot from a task worktree. The scripts own Recent Shipped, the anchor, and the ACTIVE marker.

---

## Phases

| Phase | Means | The Pilot asks for | Not yet (opt-in later) |
|-------|-------|--------------------|------------------------|
| **Build** | No external users. Building the first shippable slice. | ACTIVE milestone plus the next one, ship blockers, deploy target | Metrics, research, competitors, OKRs |
| **Launch** | First external availability: store listing, public URL, invite list. | Release steps as tasks; one phase metric with a Source if the product already emits it | Surveys, interviews, competitive review |
| **Traction** | External users exist and the product emits signal. | One to three metrics with Sources; feature inventory if useful | OKRs, personas, moats |
| **Grow** | Repeatable acquisition or retention. | Full-scope docs on request; research and competitive reviews when the human turns them on | — |
| **Mature** | Optimization and expansion. | Whatever the human turns on | — |

Legacy names map without edits: Ideation and MVP are Build; Validate is Traction; Monetize is Traction or Grow. Existing Pilots keep their phase names.

**Phase triggers** are observable: a deployment, a store status, a user count read from a Source, a passing Check. Never a date, never "feels ready", and never a research deliverable such as "ten interviews completed". Research is a task someone may choose to do; it is not a gate. A trigger that cannot be checked by command is written as `manual — <evidence that would satisfy it>` and does not pause anything.

---

## Mode Detection

| Signal | Mode |
|--------|------|
| Pilot exists; session start, dispatched task, "what should I work on", "what's blocking us" | **Orient** |
| Pilot exists; the project's queue is empty, "we're out of tickets", "what's next", "pour" | **Pour** |
| Pilot exists; merges or releases landed, scheduled run, "we shipped it", "update the plan", "milestone done" | **Reconcile** |
| Pilot exists; ACTIVE finished with no detailed next milestone, or a human changed direction | **Replan** |
| No `PRODUCT_PILOT.md` anywhere in the project | **Setup** |

Find the Pilot at `docs/product/PRODUCT_PILOT.md`, `docs/PRODUCT_PILOT.md`, or by `git ls-files`. Use its directory as `{PRODUCT_DOCS}`.

---

## Orient

Fast path. No questions, no edits.

1. Run `scripts/pilot-banner.sh` from the repo root. Without the scripts, read the Pilot and report the same items: product line, phase, blockers, the ACTIVE milestone and its open tasks, decisions past deadline, runway, staleness.
2. State whether the current task sits under the ACTIVE milestone. If it diverges, say so in one line and proceed.
3. `STALE` in the banner means Recent Shipped is behind reality: run Reconcile as a dry run before citing shipped work.
4. `STARVED` means no open ACTIVE task and nothing pourable: switch to Pour, and if Pour finds nothing, report to the Owner.
5. Never ask "should we advance the milestone?" Advancement is Reconcile's job and runs on evidence.

Output stays under 25 lines. A dispatcher pastes this output into every task packet; see the Dispatcher block in `references/AGENT_INSTRUCTION_REFERENCE.md`.

---

## Pour

Run when the project's tracker shows nothing ready for this project. Pour turns roadmap tasks into tickets; it never invents work.

1. `scripts/pilot-pour.sh` lists the `[unpoured]` tasks under the ACTIVE milestone and the next one, and names the tracker it will use: Beads (`bd`) when the repo has `.beads`, GitHub Issues when it has a GitHub origin, otherwise payloads only.
2. `scripts/pilot-pour.sh --apply` creates one ticket per task (title: the task text; body: milestone, Completion signal, Check; labels from `--labels` or the Pilot's `<!-- Pour labels: … -->` comment), dedupes by title first, and writes each ticket ID back into the Pilot in place. It refuses to create tickets from a Pilot that differs from `origin/main` unless you pass `--trust-local`.
3. For a tracker the script cannot drive, such as Linear, create the ticket with your own tool and run `scripts/pilot-pour.sh --tag N ID` to write the ID back.
4. The Owner commits the edited Pilot by PR. Dispatch the tickets through the normal queue.
5. `STARVED` means nothing is pourable: do not manufacture tasks. Report it to the Owner, naming the next sketched milestone. The Owner runs Replan.

Intake order for a dispatcher: human-filed tickets first, then confirmed bugs, then poured milestone tasks, then maintenance candidates. Poured tasks outrank dependency bumps and simplification sweeps because they move the product.

---

## Reconcile

Evidence-driven maintenance. Runs after merges and releases, on a schedule, or when asked. No questions.

1. Run `scripts/pilot-reconcile.sh` and read the dry-run output: shipped count, ACTIVE Check result, open task count, phase transition Check, decisions due, runway.
2. Tick tasks whose tickets are closed or whose PRs are merged, and put the evidence on the line: the merge commit SHA, a build number, a receipt path, or a CI run URL. A PR number, "merged", or a date alone is rejected by the structure check. Verify in the tracker or `git log`, never from memory. The script does not know the tracker, so this step is yours.
3. Run `scripts/pilot-reconcile.sh --run-checks --apply`. It regenerates Recent Shipped from git, sets the anchor and date, and moves `← ACTIVE` to the next milestone when the Check passes and every task is ticked. It writes a Changelog line for the move. Checks are shell commands from the Pilot, so they execute only with `--run-checks` and only when the whole working tree is identical to `origin/main`; on an unmerged branch pass `--trust-local` knowingly or leave checks skipped.
4. For each agent-tier decision past its Deadline: apply the Default to the thing it governs, move the row to the ROADMAP.md Decision Log with "default applied at deadline", and remove it from Decision Pending.
5. Blockers: remove a blocker only with evidence (merged PR, passing build, deploy readback). Add a new one only if it stops a release, with a ticket.
6. `phase transition: check=PASS` means the trigger holds: change the phase label, replace the Phase Transitions row with the next transition, add a Changelog line. Update which docs are maintained per the Phases table.
7. `ADVANCE: … no next milestone` means the roadmap is exhausted: run Replan.
8. Commit the Pilot with the evidence in the message. Land by PR when the repo requires it.

When a human is present and something is ambiguous, state the assumption in the commit body rather than asking.

---

## Replan

Runs when the ACTIVE milestone is done and the next one is only a sketch, when a human changes direction, or when a human-tier decision was answered.

1. Detail the next milestone from the ROADMAP.md sketch: two to six tasks, each shippable in one pull request, each tagged `[unpoured]`; one `Check` command; one Completion signal.
2. Ask a human at most three questions, and only if the repo, tracker, and ROADMAP do not already answer them: what ships next, what must be true before it can ship, what is off-limits. With no human present, write the proposal and add a Decision Pending row (Tier `human`, Default = the proposal, Deadline seven days out). Work starts on the proposal immediately.
3. Do not add research tasks (interviews, surveys, competitor studies) unless the human asked for them in this exchange. An agent may do desk research inside a task; it does not become a task or a gate.
4. Record the direction change in the ROADMAP.md Decision Log.

---

## Setup

Research-first. No interview. Produces a working Pilot from what exists.

### Step 0: Resolve `{PRODUCT_DOCS}`

Existing product docs directory, else `{existing docs dir}/product/`, else `docs/product/`. If the directory is gitignored, stop and report; the Pilot must be version-controlled.

### Step 1: Research the project

Read, in this order, and stop when the draft can be filled: README and package manifests; routes, screens, Cloud Functions, or entry points; `git log --oneline -50`; existing product docs (PRD, roadmap, specs); the tracker if present (`bd ready`, Linear, GitHub Issues); store listing or website if the README links one; the web for the product category when search tools exist, for context only. Do not fabricate competitors, users, or numbers from this research. Record only what a source said.

### Step 2: Draft the Pilot (Lean scope)

Fill `templates/PRODUCT_PILOT_TEMPLATE.md` and `templates/ROADMAP_TEMPLATE.md`:

| Field | Derive from |
|-------|-------------|
| Description | README; one to three sentences |
| Phase | No deploy target found: Build. Deployed or listed, no user evidence: Launch. Metrics with real values: Traction. |
| ACTIVE milestone | The smallest shippable slice evident in open work: open PRs, ready tickets, TODOs, the last ten commits |
| Tasks | Two to six, one PR each, all `[unpoured]` unless a ticket already exists |
| Check | A command the repo already has: a test target, a build, a deploy readback. None found: `manual — <evidence>` |
| Blockers | Only what stops a release today, with a ticket if one exists |
| Phase metric | One, with a Source command, only if the product already emits it. Otherwise "none until Launch" |
| Decision Pending | D1 "Confirm product framing (agent-drafted)", Tier `human`, Default `proceed`, Deadline seven days out |
| Owner | The persona or person who will land Pilot PRs |

Every `[PLACEHOLDER: …]` becomes real content or `[TODO: …]`. Nothing else survives.

### Step 3: Wire it in

Add the reference block from `references/AGENT_INSTRUCTION_REFERENCE.md` **inside** the section of the instruction file that dispatchers copy into task packets (a "Read first" block when one exists). Install `scripts/`, the SessionStart hook, the pre-commit guard, and the CI check from the same reference. Remove product context that now duplicates the Pilot.

### Step 4: Verify

Run `scripts/pilot-grep-checks.sh --ci`. It must exit 0. Run `scripts/pilot-banner.sh` and confirm the output is what a worker should read first.

### Step 5: Hand off

With a human present, show the draft and take edits; ask at most five questions, only for fields still marked `[TODO]`: what the product is, who it is for, what ships next, what blocks shipping, where it deploys. Unattended, commit the draft with D1 open and continue; work starts on the ACTIVE milestone now.

### Full scope

Only on explicit request. Adds PRODUCT_OVERVIEW, FEATURE_INVENTORY, METRICS_AND_OKRS, USER_RESEARCH, and COMPETITIVE_LANDSCAPE from the templates, filled by research and marked `[TODO]` where sources are silent. Full scope never asks for interviews, survey scores, competitor pricing, or keyword volumes. Legacy Micro and Lite scopes are treated as Lean.

---

## File Contract (format 3.0)

- 140 lines or fewer. Detail lives in ROADMAP.md.
- Exactly one `← ACTIVE` marker, at the end of the milestone line.
- Every task line is `- [ ] [TICKET-ID] text` or `- [ ] [unpoured] text`. A task waiting on a decision ends with `(blocked-on D<n>)`.
- A ticked task cites execution evidence on its line: a commit SHA, a build number, a receipt or artifact path, or a CI run URL. A PR number, "merged", or a date alone does not count, and `pilot-grep-checks.sh` rejects it.
- Every milestone has `Check:` with one backticked command, or `manual — <evidence>`, and a Completion signal.
- A milestone is two to six tasks; a task is one pull request. Split anything larger.
- Blockers are bullets with unblock condition, owner, ticket, since-date. No prose paragraphs.
- Decision Pending has seven columns: ID, Decision, Tier, Default, Deadline, Owner, Since. Empty reads `_No pending decisions._`.
- Recent Shipped is regenerated; its heading carries the since-date and its comment names the Shipped paths. The anchor is the merge base with `origin/main`, so it survives a squash merge.
- Phase Transitions holds the next transition only, with a Check column.
- Metrics Snapshot is optional before Traction. Each row has a Source. Pre-launch reads `_Pre-launch: no metrics tracked until first external users._`
- Open Tooling Gaps names what is not enforced in this repo. Keep the section even when empty.
- Product Docs Index appears in Full scope only.
- Changelog is append-only and structural.

`scripts/pilot-grep-checks.sh` enforces the checkable subset; `references/AUDIT_PROMPT_PACK.md` is an optional deep review for Full-scope Pilots before a phase transition.

---

## Enforcement

| Mechanism | Where it runs | What it guarantees |
|-----------|---------------|--------------------|
| `pilot-banner.sh` | SessionStart hook; pasted into dispatched task packets | Every session and every worker sees phase, blockers, ACTIVE tasks, runway |
| `pilot-grep-checks.sh --pre-commit` | Git pre-commit | No structural defect lands; anchor cannot drift more than 20 commits without a Pilot edit |
| `pilot-grep-checks.sh --ci` | Pull-request CI | Same contract for workers that run no local hooks |
| `pilot-reconcile.sh --run-checks --apply` | Scheduled job or post-merge step run by the Owner on the merged state | Recent Shipped, anchor, and ACTIVE reflect git and the Checks; Checks run only when the working tree is identical to `origin/main` |
| `pilot-pour.sh --apply` | The dispatcher or Owner, when a project queue is empty | `[unpoured]` tasks become tracker tickets with the Check as acceptance, and their IDs are written back |

What this does not reach is listed in `TOOLING_GAPS.md`. Write the repo-specific gaps into the Pilot's Open Tooling Gaps section.

---

## Output Standards

- Never invent metric values, targets, competitor facts, commit hashes, or ticket IDs. Use a Source, `git`, or the tracker; otherwise write `[TODO: …]`.
- Never write a `Check` you did not run or cannot run from the repo root. Write `manual — <evidence>` instead.
- No `[PLACEHOLDER: …]` survives into a generated file.
- Do not round: "28%" not "about 30%".
- In any review of a Pilot, lead with what is stale, blocked, or unverifiable. Do not use good, solid, clean, comprehensive, thorough, or "looks right".
- Do not describe a rule as enforced unless a hook, a CI job, or a script enforces it in this repo.

---

## Migrating a 2.x Pilot

1. Run `scripts/pilot-grep-checks.sh --banner` and fix every FAIL: one ACTIVE, 140 lines, required sections.
2. Tag every task `[TICKET-ID]` or `[unpoured]`.
3. Add a `Check:` line to each milestone; use `manual — …` where no command exists yet.
4. Convert Decision Pending to the seven columns. Give each row a Tier, a Default, and a Deadline.
5. Replace the Metrics Snapshot Category column with Source. Drop rows without a Source or mark them `[TODO: source]`.
6. Put `<!-- Shipped paths: … -->` under the Recent Shipped heading and run `scripts/pilot-reconcile.sh --apply` (no Checks run without `--run-checks`).
7. Set `Owner` to a persona, add the Edit policy comment, bump `format version` to 3.0, add a Changelog line.

The reconcile script already works on 2.2 files for Recent Shipped and the anchor. Automatic advancement needs the 3.0 task tags and Check lines.

---

## Example: Filled Pilot (format 3.0, fictional product)

> ```
> <!-- Product Pilot format version: 3.0 -->
> <!-- Pilot scope: Lean -->
> <!-- Last updated: 2026-10-13 -->
> <!-- Last commit captured: a3f9c12 -->
> <!-- Owner: Product Leader -->
> ```
>
> ## Quick Orientation
>
> **Ledgerlite** is a single-user expense tracker for freelancers. iOS, local storage, no account.
>
> **Current phase:** 1 — Build
> **Phase metric:** none until Launch — Source: `none`
>
> ### What's Blocking Ship
>
> - **No signing certificate** — Unblocked when: a distribution certificate is installed on the CI runner. Owner: Shane. Ticket: LL-9. Since: 2026-10-10
>
> ## Active Milestones
>
> ### Phase 1: Build
>
> - **[1.2] First export** ← ACTIVE
>   - [x] [LL-4] CSV export of one month
>   - [ ] [LL-7] Share sheet for the CSV
>   - [ ] [unpoured] Empty-state copy when no expenses exist
>   - Check: `xcodebuild test -scheme Ledgerlite -only-testing:ExportTests`
>   - Completion signal: Export tests pass on CI
>
> - **[1.3] TestFlight build**
>   - [ ] [unpoured] Bump version and archive on CI
>   - Check: `manual — build visible in TestFlight`
>   - Completion signal: First external tester installs
>
> ## Decision Pending
>
> | ID | Decision | Tier | Default | Deadline | Owner | Since |
> |----|----------|------|---------|----------|-------|-------|
> | D1 | Export date format | agent | ISO 8601 | 2026-10-20 | Product Leader | 2026-10-13 |
>
> ## Recent Shipped (since 2026-10-01)
>
> <!-- Shipped paths: Ledgerlite -->
>
> - a3f9c12 feat: CSV export of one month
>
> ## Phase Transitions
>
> | Transition | Trigger | Check |
> |-----------|---------|-------|
> | Build → Launch | App visible in TestFlight | `manual — TestFlight readback` |
>
> ## Metrics Snapshot
>
> _Pre-launch: no metrics tracked until first external users._
>
> ## Open Tooling Gaps
>
> - No CI check on this repo yet; freshness relies on the pre-commit guard.
>
> ## Changelog
>
> - 2026-10-13 — Migrated to format 3.0
