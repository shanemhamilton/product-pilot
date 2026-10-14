<!--
This is the canonical agent-instruction file. CLAUDE.md and GEMINI.md are symlinks to it.
Edit this file, never the symlinks.
-->

# Product Pilot

Product Pilot — product context for autonomous coding agents. Creates and maintains a `PRODUCT_PILOT.md` (format 3.0): phase, the ACTIVE milestone with ticket-tagged tasks and a runnable Check, ship blockers, decisions with defaults and deadlines, recent ships from git, and runway.

## Core Rules
- **Skill source**: `SKILL.md`. Templates in `templates/`, wiring and the optional deep-review pack in `references/`, the landing page in `docs/`.
- **Scripts**: `scripts/pilot-banner.sh`, `scripts/pilot-grep-checks.sh`, `scripts/pilot-reconcile.sh`. POSIX sh plus awk, no dependencies. Run `scripts/selftest.sh` after any script change; it must print `selftest: all checks passed`.
- **Principles that gate every change**: zero-to-one first (no research, interview, OKR, or competitor gates before Traction, and only on opt-in after); gates stop releases, never the work queue; evidence over claims; agents decide routine choices and record them; one Owner edits the Pilot, by PR.
- **Enforcement claims**: never describe a rule as enforced unless a script, hook, or CI job in `references/` enforces it. `TOOLING_GAPS.md` lists what remains unenforced.
