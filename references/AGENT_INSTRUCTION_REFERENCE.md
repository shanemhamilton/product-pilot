# Wiring Product Pilot into agents, dispatchers, hooks, and CI

Replace `{PRODUCT_DOCS}` with the resolved path from Setup (for example `docs/product/`). Replace `{SCRIPTS}` with where you installed the scripts (for example `scripts/`).

## 1. Placement rule

Put the reference block **inside** the part of the instruction file that gets copied into task packets. If the file has a "Read first" block that dispatchers copy verbatim, the Pilot pointer goes in that block. A pointer outside it is never seen by a worker that only receives the packet.

For a product split across repositories, one repository holds the Pilot (the workspace or coordination repo). Every other repository's Read-first block gets the one-line pointer in section 2.3.

## 2. Reference blocks

### 2.1 CLAUDE.md or AGENTS.md (one block serves both)

```markdown
## Product Pilot

Before choosing or starting work, run `{SCRIPTS}pilot-banner.sh` (or read
`{PRODUCT_DOCS}PRODUCT_PILOT.md`). It gives the phase, what blocks a release, the
ACTIVE milestone and its open tasks, decisions past deadline, and runway.

Rules: a blocker or a pending decision stops a release, not your task. Routine
product choices are yours: decide, record one line, continue. If your task is not
under the ACTIVE milestone, do it and note the divergence. Only the Pilot Owner
edits the Pilot, by PR; never edit it from a task worktree.

After merges or releases the Owner runs `{SCRIPTS}pilot-reconcile.sh --apply`.
When the queue is empty, pour `[unpoured]` tasks from the ACTIVE milestone into
the tracker before falling back to maintenance work.
```

### 2.2 .cursorrules or a custom system prompt

```
Read {PRODUCT_DOCS}PRODUCT_PILOT.md before starting work. Work the ACTIVE milestone's
open tasks first. Blockers and pending decisions stop releases, not tasks. Decide
routine product choices yourself and record them. Do not edit the Pilot; its Owner
does, by PR, after running {SCRIPTS}pilot-reconcile.sh --apply.
```

### 2.3 One-line pointer for a sub-repository

```markdown
Product context: `<workspace-repo>/{PRODUCT_DOCS}PRODUCT_PILOT.md` (read the ACTIVE milestone before starting).
```

## 3. Dispatcher block

For a coordinator that builds queues and sends task packets to workers (a ticket runner, a fleet dispatcher).

```markdown
## Product Pilot (dispatcher)

- Intake order: human-filed tickets, confirmed bugs, then `[unpoured]` tasks from
  the Pilot's ACTIVE milestone (pour them into the tracker first), then maintenance
  candidates such as simplification sweeps and dependency bumps.
- Every task packet includes the output of `{SCRIPTS}pilot-banner.sh` run against
  the owning repo at its current main. Workers that cannot read the repo still
  receive the phase, blockers, ACTIVE tasks, and runway this way.
- Pour when the project queue is empty: one ticket per `[unpoured]` task, body =
  milestone, Completion signal, and Check. Write the ticket ID back to the Pilot
  through the Owner persona. Report `STARVED` to the Owner when nothing is pourable.
- Reconcile after merges and releases, or once per cycle: the Owner persona runs
  `{SCRIPTS}pilot-reconcile.sh --apply`, ticks tasks whose tickets closed, applies
  agent-tier decision Defaults past their Deadline, and lands the edit by PR.
- The Pilot's "What's Blocking Ship" is the release blocker list. Do not keep a
  second list elsewhere; reference these entries by name.
```

## 4. Hooks

### 4.1 Claude Code `.claude/settings.json`

SessionStart hooks run a shell command and add its stdout to the session. Verified in use on 2026-10-13 in two tenant repos.

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "sh {SCRIPTS}pilot-banner.sh; sh {SCRIPTS}pilot-grep-checks.sh --banner" } ] }
    ]
  }
}
```

### 4.2 Codex `.codex/hooks.json`

Same shape; verified in a tenant repo on 2026-10-13.

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "sh {SCRIPTS}pilot-banner.sh; sh {SCRIPTS}pilot-grep-checks.sh --banner" } ] }
    ]
  }
}
```

### 4.3 Git pre-commit

Add to the repo's pre-commit hook (`.githooks/pre-commit` with `git config core.hooksPath .githooks`, or `.git/hooks/pre-commit`):

```sh
sh {SCRIPTS}pilot-grep-checks.sh --pre-commit
```

It fails the commit on a structural defect, or when the anchor is more than 20 commits behind HEAD and the commit does not touch the Pilot.

## 5. CI

Workers whose harness runs no local hooks are covered only by CI. Copy `references/ci/pilot-check.yml` to `.github/workflows/` for GitHub Actions. For Buildkite, add a step:

```yaml
  - label: "product pilot"
    command: "sh {SCRIPTS}pilot-grep-checks.sh --ci"
    if: build.pull_request.id != null
```

The checkout needs full history (`fetch-depth: 0` on GitHub Actions) so the anchor commit can be resolved.

## 6. Scheduling reconcile

The skill does not schedule anything. Run `{SCRIPTS}pilot-reconcile.sh --apply` from whatever already runs on a cadence in the host: a nightly workflow, the coordinator's cycle, a post-merge job. The command is idempotent and writes only when something changed.

## 7. Notes for the Buzz desktop-app fleet (observed 2026-10-13)

These were read from `~/.buzz` and the Buzz source on that date. Re-verify before relying on them.

- The delivery protocol (`nh-delivery-v6.3`) requires each task packet to include "the current repository Read first block verbatim". Section 1 above follows from this: the pointer must be inside that block.
- The documented intake order is Linear project tickets, confirmed bugs, simplification candidate beads, then dependency bumps. Section 3 inserts poured milestone tasks after confirmed bugs.
- Personas running in the Antigravity nest sandbox cannot read `AGENTS.md` under `~/Projects`. The banner pasted into the packet is the only Pilot content such a worker receives.
- The ACP harness assembles the system prompt from base, workspace, agent-instructions, team-instructions, core-memory, huddle, and channel-canvas sections. A one-line pointer in the team-instructions or the persona prompt reaches every session start; the scripts cannot be run from inside a sandboxed nest.
- Product sub-repositories (driver backend, rider app, shared packages, iOS app) carry their own Read-first blocks without a Pilot reference. Section 2.3 is for them.
