# Enforcement and remaining gaps

What Product Pilot 3.0 enforces, by what mechanism, and what it still cannot reach. Copy the gaps that apply to your repo into the Pilot's Open Tooling Gaps section.

## Why this file exists

A 2.2-era audit of one deployment found zero session-start invocations of the skill over seven days and 39 commits in 15 days with no Pilot edit. Version 2.2 answered by asking tenants to acknowledge the gap. Version 3.0 answers by moving the guarantees out of the agent's voluntary compliance and into scripts, hooks, and CI.

## Enforced

| Guarantee | Mechanism | Install |
|-----------|-----------|---------|
| The agent sees phase, blockers, ACTIVE tasks, decisions due, and runway before acting | `scripts/pilot-banner.sh` in a SessionStart hook; its output pasted into dispatched packets | `references/AGENT_INSTRUCTION_REFERENCE.md` sections 3 and 4 |
| No structural defect lands: one ACTIVE marker, required sections, no placeholders, real anchor, 140 lines, tagged tasks | `scripts/pilot-grep-checks.sh --pre-commit` and `--ci` | Sections 4.3 and 5 |
| No task is ticked without execution evidence (commit SHA, build number, receipt path, or CI run URL) | Same | Same |
| A task is ticked, with its evidence on the line, when its ticket is closed and the tracker carries that evidence (Beads close reason or last comment, merged GitHub PR, completed Linear issue with a merged PR attachment) | `scripts/pilot-reconcile.sh --apply` | Section 6 |
| Recent Shipped matches git; the ACTIVE marker moves only when the Check passes and every task is ticked | `scripts/pilot-reconcile.sh --run-checks --apply` | Section 6 |
| An empty queue refills from the roadmap instead of starving | `scripts/pilot-pour.sh --apply` run by the dispatcher or Owner | Dispatcher block, section 3 |
| The scripts themselves work | `scripts/selftest.sh` | Run it after any script change |

## Not enforced

1. **Workers that run neither repo hooks nor CI.** A sandboxed worker that cannot read the repo receives the Pilot only through the packet. If the dispatcher omits the banner, the worker has no product context. The dispatcher block in the reference is the control; nothing in this skill can verify that a dispatcher applied it.
2. **Ticks the tracker cannot prove.** Reconcile ticks a task only when its ticket is closed and carries execution evidence. A closed ticket without evidence, a tag no tracker resolves, a Linear tag without `LINEAR_API_KEY`, and a GitHub tag `gh` cannot view are reported, not ticked; those ticks are the agent's, and a tick written without evidence is caught only by the structure check. `selftest.sh` runs offline (no origin, no key), so it exercises the Beads path when `bd` is installed and never the GitHub or Linear paths.
3. **Checks are only as strong as their command, and they are code.** A milestone with `Check: manual — …` never auto-advances. A Check that always passes advances a milestone that is not done. Because a Check is a shell command anyone with a merged Pilot edit can plant, reconcile executes Checks only with `--run-checks`, only when the whole working tree is identical to `origin/main`, and prints each command first. That makes review of what lands on main the control; nothing in the script inspects what a Check does.
4. **Metric Sources need telemetry.** A metric without a Source stays `[TODO: source]`. The skill does not build analytics.
5. **Scheduling.** Reconcile runs only when something runs it. The skill ships no scheduler.
6. **Decision Defaults.** The script reports agent-tier decisions past their Deadline. Applying the Default and logging it is the Owner's edit; the script does not change the thing the decision governs.
7. **Skill invocation.** Nothing forces an agent to invoke this skill. The banner makes the Pilot's content reach the agent anyway; the skill's modes are for agents that act on it.
8. **The banner is repo content.** `pilot-banner.sh` prints Pilot text into every session and packet, so a Pilot edit that lands puts words in front of every agent. The banner labels whether the file matches `origin/main`; review of Pilot PRs by the Owner is the control.
9. **Pour dedupes by exact title only.** `pilot-pour.sh` skips a task when a ticket already has that title: an open one on Beads or GitHub, one not completed or canceled in the team on Linear. A reworded duplicate is not detected.
10. **Anchor drift.** `pilot-grep-checks.sh --pre-commit` warns, and does not refuse, when the anchor is more than 20 commits behind HEAD and the commit does not touch the Pilot, because the edit policy forbids workers from touching the Pilot from a task worktree. `PILOT_STRICT_ANCHOR=1` in the hook environment restores the refusal. The scheduled reconcile (reference section 6) is the freshness control, and item 5 applies to it.
