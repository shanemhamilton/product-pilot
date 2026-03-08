# Agent Instruction File — Product Pilot Reference Block

Add this section to your agent instruction file. Place it near the top, after user preferences but before engineering instructions.

**Which file?**
- `CLAUDE.md` → Claude Code
- `.cursorrules` → Cursor
- `AGENTS.md` → GitHub Copilot
- Custom system prompt → Other tools

**Important:** Replace `{PRODUCT_DOCS}` below with the actual resolved path from Step 0 (e.g., `docs/product/`, `documentation/product/`).

---

## For CLAUDE.md (Claude Code / Cowork)

```markdown
## Product Pilot — MANDATORY

Before starting work, read `{PRODUCT_DOCS}PRODUCT_PILOT.md`. It tells you what phase
we're in, what milestones are active, and what to work on next.

Do NOT skip this. Without product context, you risk building the wrong thing.

After finishing work, follow the session-end checklist in the Pilot to update product docs.
If available, use the relevant Product Manager skill (feature-spec, roadmap-management,
metrics-tracking, etc.) to ensure updates follow PM best practices. Commit doc changes
alongside code changes.

For deep context: see the files in `{PRODUCT_DOCS}` (Pilot, vision, features, roadmap,
metrics, research, competitive).
```

## For .cursorrules (Cursor)

```
# Product Pilot — MANDATORY

Before starting work, read {PRODUCT_DOCS}PRODUCT_PILOT.md for product context.
After finishing work, follow the session-end checklist in the Pilot to update product docs.
Commit doc changes alongside code changes.

See {PRODUCT_DOCS} for: vision, features, roadmap, metrics, research, competitive landscape.
```

## For AGENTS.md (GitHub Copilot)

```markdown
## Product Context

Before starting work, review `{PRODUCT_DOCS}PRODUCT_PILOT.md` for current phase,
active milestones, and product direction. After completing work, check the session-end
checklist in the Pilot and update any relevant product docs in `{PRODUCT_DOCS}`.
```

## For Custom System Prompts

```
You must read {PRODUCT_DOCS}PRODUCT_PILOT.md at the start of every session. It contains
the current product phase, active milestones, key metrics, and instructions for maintaining
product documentation. Follow the session-end checklist before finishing your work.
```
