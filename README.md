[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

# Product Pilot

**Give your AI coding agent product awareness.**

Product Pilot is an AI coding-agent skill, tested with Claude Code and Codex, that bootstraps self-maintaining product documentation for any project. It creates a lightweight Product Pilot file that tells your agent what phase you're in, what milestone is active, what metrics matter, and what docs to update when work is done. No more repeating product context every session.

## Install

Copy or clone the skill into your agent's skills directory.

For Claude Code:

```bash
cp -r product-pilot ~/.claude/skills/product-pilot
```

```bash
git clone https://github.com/shanemhamilton/product-pilot.git ~/.claude/skills/product-pilot
```

For Codex:

```bash
cp -r product-pilot ~/.codex/skills/product-pilot
```

```bash
git clone https://github.com/shanemhamilton/product-pilot.git ~/.codex/skills/product-pilot
```

## Usage

In your AI coding agent, say any of:

- "Set up a product pilot"
- "Create product context for my project"
- "Make my agent product-aware"
- "Read the product pilot"

The skill runs a short interview about your product, then generates a product docs directory with your Product Pilot and supporting markdown files. All generated files are markdown — optimized for AI agents to read and maintain.

The skill auto-detects your project's existing docs directory (`docs/`, `documentation/`, `doc/`, etc.) and creates a `product/` subdirectory inside it. If no docs directory exists, it defaults to `docs/product/`.

## Scope Options

| Scope | What you get | Interview | Time |
|-------|-------------|-----------|------|
| **Full** | Product Pilot + 6 supporting docs + agent instruction reference | 12 questions | 15-20 min |
| **Lite** | Product Pilot + 3 supporting docs + agent instruction reference | 10 questions | 10-15 min |
| **Micro** | Product Pilot + agent instruction reference only | 8 questions | 5-10 min |

### Generated files (Full scope)

```
{your-docs-dir}/product/
  PRODUCT_PILOT.md          # The main file your agent reads every session
  PRODUCT_OVERVIEW.md        # What the product is, who it's for, core principles
  FEATURE_INVENTORY.md       # What's built, what's planned, feature status
  ROADMAP.md                 # Phased milestones with checklists and triggers
  METRICS_AND_OKRS.md        # KPIs, targets, and quarterly objectives
  USER_RESEARCH.md           # User segments, pain points, assumptions to validate
  COMPETITIVE_LANDSCAPE.md   # Competitors, differentiators, positioning
```

## Parallel Agent Mode

If your host supports parallel agents and the user has enabled or approved delegation, the skill can parallelize Full-scope document generation across separate workers. Lite and Micro scopes rarely justify the overhead.

## Update Mode

If a Product Pilot already exists, the skill switches to update mode: it asks what changed and updates only the relevant files. Run periodically to keep docs current.

## Recommended Agent Instruction Setup

The skill adds a **Product Pilot reference block** to your agent instruction file automatically during setup. That block tells your agent to read the Pilot at session start and follow the session-end checklist.

Supported instruction files include `CLAUDE.md` for Claude Code, `AGENTS.md` for Codex and GitHub Copilot, `.cursorrules` for Cursor, and custom system prompts for other tools.

For better results, add these rules manually to the same instruction file. They address the two most common failure modes in AI-assisted product work — sycophantic status reviews and fabricated data in docs.

### Anti-sycophancy

```markdown
## Product Review Standards

When reviewing milestones or running a Pilot review:
- Lead with what is stale, blocked, or below target — not with what is done
- Check completion signal criteria explicitly; "looks done" is not an assessment
- A clean review with no issues is a sign you didn't look hard enough
- Name issues specifically: metric name, current value, and target — not "needs work"
```

### Anti-hallucination

```markdown
## Product Doc Standards

When generating or updating product docs:
- Never invent metric targets — only use values provided by the user; mark gaps as [TODO: add target]
- Never fabricate competitor data, pricing, or feature comparisons — mark as [TODO: research]
- No [PLACEHOLDER: ...] marker may survive into final files — replace with real content or [TODO: ...]
- Don't round numbers: write "28% retention" not "~30%"
```

These rules are intentionally omitted from the skill itself — they may conflict with your project's existing agent instruction style. Add the ones that fit.

## What's new in v2.3

v2.3 expands Product Pilot from a Claude Code-oriented skill into a multi-agent skill tested with Claude Code and Codex. The core Product Pilot format remains v2.2.

**Compatibility changes:**

- Added Codex install instructions for `~/.codex/skills/product-pilot`.
- Added `agents/openai.yaml` metadata for Codex skill discovery and UI display.
- Replaced the Claude-specific instruction reference with `references/AGENT_INSTRUCTION_REFERENCE.md`, covering `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, and custom system prompts.
- Reframed Teams Mode as optional Parallel Agent Mode, gated on host support and user approval.

## What's new in v2.2

v2.2 is a structural rewrite of the Pilot template, derived from a 5-angle adversarial audit of a v2.x deployment in production. Tenant Pilots generated by older versions should be regenerated through Update mode.

**Template structure changes:**

- `Agent Operating Instructions` is now placed **before** Active Milestones, so an agent reading top-down hits operating rules before milestone state. In v2.1 it appeared more than halfway down the file; tenant extensions pushed it further, and agents drifted.
- New **`What's Blocking Ship`** section in Quick Orientation. Bulletized only — one bullet per blocker with unblock condition, owner, and since-date. Prose paragraphs are explicitly a structural defect.
- New **`Recent Shipped (since DATE)`** section with a pinned regenerate command (`git log --oneline --since=YYYY-MM-DD ...`) and a `Last commit captured` header field. Together these give the Pilot a coverage anchor — agents can tell at a glance whether the doc has seen recent work.
- New **`Decision Pending`** section for aging proposals. Each row needs an owner and a since-date; rows older than 30 days force a kill or schedule decision.
- New **`Open Tooling Gaps`** section. Required even when empty, so tenants flag harness limitations rather than silently rely on agent compliance.
- New **`Changelog`** section at the bottom for structural changes to the Pilot.
- Product Docs Index now has a **`Last reviewed`** column. Cadence without per-doc timestamps was non-actionable.
- Phase Transitions table is trimmed to the **next transition only**. Full transition history lives in `ROADMAP.md`.
- Metrics Snapshot adds a **Category** column (AARRR family) so coverage gaps in metric families are visible at a glance.

**New audit pack:**

`references/AUDIT_PROMPT_PACK.md` ships with five angle prompts — drift, coverage, structure, sister-doc consistency, session compliance — plus deterministic grep-checks and a challenge-all-positive gate. Each angle prompt has anti-sycophancy quotas baked in (≥3-5 defects, banned softening words, lead-with-worst). Use the pack before milestone advancement, phase transition, or any time the Pilot has not been reviewed in 30+ days.

**Honesty about enforcement:**

The skill no longer describes session-start reads or session-end doc updates as enforced. They are the agent's voluntary responsibility. See `TOOLING_GAPS.md` for the harness gaps and what tenants can do today (shell-based SessionStart hooks, pre-commit checks) to close them.

## License

[MIT](LICENSE)
