# Agent Instruction File — Product Pilot Reference Block

Add this section to your agent instruction file. Place it near the top, after user preferences but before engineering instructions.

**Which file?**
- `CLAUDE.md` — Claude Code
- `AGENTS.md` — Codex and GitHub Copilot
- `.cursorrules` — Cursor
- Custom system prompt — other tools

**Important:** Replace `{PRODUCT_DOCS}` below with the actual resolved path from Step 0 (e.g., `docs/product/`, `documentation/product/`).

**Honesty note:** The blocks below ask the agent to read the Pilot at session start and update docs at session end. These are the agent's responsibilities — they are NOT enforced by the harness today. See `TOOLING_GAPS.md` for what the host harness does and does not guarantee, and what hooks tenants can add to close the gap.

---

## For CLAUDE.md (Claude Code)

```markdown
## Product Pilot — read at session start

Before starting work, read `{PRODUCT_DOCS}PRODUCT_PILOT.md`. It tells you what phase
we're in, what milestones are active, what's blocking ship, and what to work on next.

Without product context, you risk building the wrong thing. This is a voluntary
read — no harness check enforces it — so the responsibility is yours.

After finishing work, follow the Session End checklist in the Pilot to update
product docs. If available, use the relevant Product Manager skill (feature-spec,
roadmap-management, metrics-tracking, etc.). Update doc changes in the same commit
as the code change when practical.

For deep context, see the files in `{PRODUCT_DOCS}` (Pilot, vision, features, roadmap,
metrics, research, competitive).

When reviewing or updating product docs: lead with what's stale or blocking, not
what's working. Never invent metric targets or competitor data — mark unknowns as
[TODO]. A review that finds nothing wrong is a sign you didn't look hard enough.
```

## For .cursorrules (Cursor)

```
# Product Pilot — read at session start

Before starting work, read {PRODUCT_DOCS}PRODUCT_PILOT.md for product context.
After finishing work, follow the Session End checklist in the Pilot to update
product docs. Update doc changes in the same commit as the code change when practical.

This is a voluntary read — there is no enforcement layer.

See {PRODUCT_DOCS} for: vision, features, roadmap, metrics, research, competitive landscape.
```

## For AGENTS.md (Codex / GitHub Copilot)

```markdown
## Product Context

Before starting work, review `{PRODUCT_DOCS}PRODUCT_PILOT.md` for current phase,
active milestones, what's blocking ship, and product direction. After completing
work, check the Session End checklist in the Pilot and update any relevant product
docs in `{PRODUCT_DOCS}`.

This is the agent's responsibility — no harness check enforces it.
```

## For Custom System Prompts

```
Read {PRODUCT_DOCS}PRODUCT_PILOT.md at the start of every session. It contains
the current product phase, active milestones, what is blocking ship, key metrics,
and instructions for maintaining product documentation. Follow the Session End
checklist before finishing your work. Compliance is voluntary; behave as if you
are the only enforcement layer.
```
