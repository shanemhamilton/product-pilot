[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

# Product Pilot

**Product context for autonomous coding agents.**

**[→ View the site](https://shanemhamilton.github.io/product-pilot/)**

Product Pilot is an agent skill, tested with Claude Code and Codex, that gives a coding agent, or a fleet of them, the product context to keep shipping with a human over the loop: the human sets direction and holds the gates, and is asked only for what only a human can supply. It maintains one file per product, `PRODUCT_PILOT.md`, under 140 lines: the phase, the ACTIVE milestone with ticket-tagged tasks and a runnable completion Check, what blocks a release, decisions with defaults and deadlines, recent ships taken from git, and how much runway the roadmap still holds. Three shell scripts keep the file true and feed it to every session and every dispatched task.

Version 3.0 is built for zero-to-one. Until a product has external users, the skill asks for three things: what ships next, what blocks shipping, and where it deploys. Interviews, surveys, personas, competitor matrices, and OKRs are opt-in workstreams that unlock later, when a human turns them on.

## Install

```bash
git clone https://github.com/shanemhamilton/product-pilot.git ~/.claude/skills/product-pilot
```

```bash
git clone https://github.com/shanemhamilton/product-pilot.git ~/.codex/skills/product-pilot
```

To pin a release instead of tracking main, add `--branch v3.0.0 --depth 1` to either clone. Releases: [github.com/shanemhamilton/product-pilot/releases](https://github.com/shanemhamilton/product-pilot/releases).

Then, in the host repo, copy or symlink `scripts/` and wire the hooks and CI check from [`references/AGENT_INSTRUCTION_REFERENCE.md`](references/AGENT_INSTRUCTION_REFERENCE.md). Run `scripts/selftest.sh` once to prove the scripts work on your machine.

## Modes

| Say | Mode | What happens |
|-----|------|--------------|
| "What should I work on?", "What's blocking us from shipping?", a dispatched task, session start | **Orient** | `pilot-banner.sh` prints phase, blockers, ACTIVE tasks, decisions due, runway. No questions. |
| "We're out of tickets. What's next?", the queue is empty | **Pour** | `pilot-pour.sh --apply` turns `[unpoured]` tasks under the ACTIVE milestone into tracker tickets and writes the IDs back. |
| "We shipped it. Update the plan.", merges or releases landed, a scheduled run | **Reconcile** | `pilot-reconcile.sh --run-checks --apply` regenerates Recent Shipped, ticks tasks whose tickets closed with evidence, runs the Checks, advances ACTIVE on evidence, reports decisions past deadline. |
| ACTIVE finished with only a sketch next, or direction changed | **Replan** | The next milestone is detailed from the roadmap. At most three questions, and only if the repo cannot answer them. |
| no Pilot in the project | **Setup** | Research-first: the agent reads the repo, tracker, store listing, and web, drafts the Pilot, and starts work. No interview. |

## Phases

Build → Launch → Traction → Grow → Mature. Phase triggers are observable: a deployment, a store status, a user count from a Source command. Never a date, and never a research deliverable. A gate stops a release; it never stops the work queue.

## Scripts

| Script | Role |
|--------|------|
| `scripts/pilot-banner.sh` | The orientation an agent reads first. Used by SessionStart hooks and pasted into task packets. |
| `scripts/pilot-grep-checks.sh` | Structure contract. `--pre-commit` blocks defects locally and warns on anchor drift past 20 commits (`PILOT_STRICT_ANCHOR=1` refuses); `--ci` blocks defects on pull requests; `--banner` reports. |
| `scripts/pilot-reconcile.sh` | Evidence-driven maintenance: Recent Shipped from git, ticks from the tracker (Beads, GitHub, Linear) with the evidence on the line, Checks, ACTIVE. Dry run by default; `--apply` writes. |
| `scripts/pilot-pour.sh` | Turns `[unpoured]` tasks into tracker tickets (Beads, Linear, GitHub Issues, or `--tag` for others) and writes the IDs back. |
| `scripts/selftest.sh` | One runnable check that the scripts behave; offline, so it covers Beads (when `bd` is installed) and not the GitHub or Linear paths. |

What these do and do not enforce is in [`TOOLING_GAPS.md`](TOOLING_GAPS.md).

## Scope

**Lean** (default): `PRODUCT_PILOT.md` and `ROADMAP.md`. **Full** (on request): adds overview, feature inventory, metrics, users, and competitive context, each filled by agent research and marked `[TODO]` where sources are silent. Earlier Micro and Lite scopes read as Lean.

```
{your-docs-dir}/product/
  PRODUCT_PILOT.md           # read first; under 140 lines
  ROADMAP.md                 # every milestone's detail, decision log, done list
  PRODUCT_OVERVIEW.md        # Full scope
  FEATURE_INVENTORY.md       # Full scope
  METRICS_AND_OKRS.md        # Full scope
  USER_RESEARCH.md           # Full scope
  COMPETITIVE_LANDSCAPE.md   # Full scope
```

## Working with a dispatcher

For a coordinator that builds queues and sends task packets, such as the Buzz desktop app's dispatcher persona, there are four wiring points:

1. The Pilot rule sits inside the "Read first" block that packets copy verbatim, so a sandboxed worker that cannot read the repo still receives it.
2. The dispatcher runs `pilot-banner.sh` against the repo's current main and pastes the output into every packet.
3. Intake order: human-filed tickets, confirmed bugs, then `[unpoured]` tasks from the ACTIVE milestone poured into the tracker, then maintenance such as dependency bumps.
4. Workers never edit the Pilot. One Owner persona runs `pilot-reconcile.sh --run-checks --apply` after merges and lands the edit by PR.

A packet for a fictional product, as a dispatcher would send it:

```
ticket      LL-7 Share sheet for the CSV · repo ledgerlite · base main@a3f9c12 · owned paths Ledgerlite/Export/
read first  (the repo's Read-first block, copied verbatim; it carries the Product Pilot rule)
pilot       Phase 1 — Build · ACTIVE [1.2] First export · 2 open, 1 unpoured
pilot       Blocking ship: no signing certificate (LL-9), a release gate, not a work gate
pilot       Decision due: D1 export date format, default ISO 8601
accept      Export tests pass on CI (milestone Check) · result thread #ledgerlite · do not edit docs/product/
```

The dispatcher block, hooks, and CI snippets are in [`references/AGENT_INSTRUCTION_REFERENCE.md`](references/AGENT_INSTRUCTION_REFERENCE.md); its last section records what was observed in the Buzz fleet's delivery protocol on 2026-10-13.

## Working with Product Design

Product Pilot owns product truth; a Product Design skill set owns design execution. Version 3.0 removes the "show three directions and wait" gate: with a human present the agent recommends one and proceeds, unattended it chooses, logs the decision, and proceeds. See [`references/PRODUCT_DESIGN_INTEGRATION.md`](references/PRODUCT_DESIGN_INTEGRATION.md).

## What's new in v3.0

- Research-first Setup replaces the interview. Lean scope is the default.
- Format 3.0: ticket-tagged tasks, a `Check` command per milestone, seven-column Decision Pending with Tier, Default, and Deadline, `Source` per metric, a Phase Transitions Check, an Owner persona and edit policy.
- Pour, Reconcile, and Replan modes for unattended operation; "ask the user" prompts removed from every mode.
- Phase ladder Build → Launch → Traction → Grow → Mature, with research and OKRs opt-in from Traction.
- Scripts: banner, grep-checks, reconcile, selftest. Hook, pre-commit, CI, and dispatcher wiring in the reference.
- Audit pack reduced to an optional deep review; minimum-defect quotas removed.

Pilots generated by 2.x keep working with the scripts for Recent Shipped and the anchor. The migration steps in `SKILL.md` add the 3.0 fields.

## License

[MIT](LICENSE)
