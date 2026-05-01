# Open Tooling Gaps

This document records limitations of Product Pilot that **cannot be fixed inside the skill or template** because they require host-harness changes. Tenants should read this before adopting Product Pilot so they understand what the skill does and does not enforce.

These gaps were surfaced by a 5-angle adversarial audit of a v2.x deployment in production. The audit observed: 7 days of skill telemetry showing zero session-start invocations of the Pilot, and 39 commits across 15 days with zero corresponding Pilot edits. The Pilot's documentation reads as if these behaviors are enforced; the harness layer does not enforce them.

The v2.2 template now has an `Open Tooling Gaps` section so tenants flag these limitations explicitly in their own Pilot rather than rediscovering them session by session.

---

## Gap 1 — No SessionStart hook contract

**What the skill claims:** The `description` field in `SKILL.md` lists "Session start" as a primary trigger. The agent instruction reference block in `references/CLAUDE_MD_REFERENCE.md` tells the host agent to "read PRODUCT_PILOT.md before starting work."

**What actually happens:** The skill fires only when the agent voluntarily invokes it, or when the user types `/product-pilot`. Most Claude Code session starts do not invoke any skill automatically.

**Evidence:** In one production deployment, Langfuse traces over a 7-day window recorded zero invocations of the `product-pilot` skill at session start, despite the agent instruction file mandating the read.

**What's needed to close this gap:** A SessionStart hook contract. Roughly:

```jsonc
// Conceptual — Claude Code would need to support this.
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "skill", "skill": "product-pilot", "args": "context" }
        ]
      }
    ]
  }
}
```

Until the harness exposes a SessionStart hook that can invoke a skill (not just a shell command), no template change can guarantee the Pilot is read at session start. Tenants relying on session-start product context should be aware that compliance is voluntary.

**What tenants can do today:** Add a deterministic shell-based SessionStart hook that prints the Pilot's first 30 lines into the session context. This is not the same as invoking the skill, but it forces the Pilot's `What's Blocking Ship` and `Active Milestones` sections in front of the agent before its first turn.

---

## Gap 2 — No session-end enforcement

**What the skill claims:** The `Session End` checklist in `PRODUCT_PILOT_TEMPLATE.md` and the agent instruction reference block both tell the agent to "update relevant docs and commit doc changes alongside code changes."

**What actually happens:** This is documentation-only. There is no pre-commit hook, no CI check, and no harness mechanism that fails when code commits ship without corresponding Pilot or sister-doc updates.

**Evidence:** In the same production deployment, 39 commits shipped in 15 days. None of them included a Pilot or sister-doc update, despite many of them being feature-shipped, milestone-complete, or metric-data commits per the checklist matrix.

**What's needed to close this gap:** Either a pre-commit hook that warns when code paths matching feature/migration patterns ship without doc updates, or a CI step that enforces the same rule on PR merge. A reference implementation belongs in `references/`, not in `SKILL.md` (the skill should not assume any specific harness).

**What tenants can do today:** Add a pre-commit hook that:
1. Checks `git diff --cached --name-only` for paths in feature directories.
2. Cross-references against changes to `{PRODUCT_DOCS}/`.
3. Warns (not blocks) if code changes ship without doc changes.

The template's v2.2 `Open Tooling Gaps` section gives tenants a place to acknowledge this limitation in their own Pilot. The CLAUDE_MD_REFERENCE.md block has been softened in v2.2 to frame the session-end checklist as the agent's responsibility, not as an enforced rule.

---

## How v2.2 addresses these gaps

The template cannot enforce what the harness does not expose. v2.2 instead:

1. **Acknowledges the gap structurally.** The new `Open Tooling Gaps` section in the Pilot template forces tenants to write down the limitation rather than pretend it doesn't exist.
2. **Adds verification grep-checks.** `references/AUDIT_PROMPT_PACK.md` includes a deterministic gitignore check, placeholder-survivor check, ACTIVE marker count, and last-commit anchor check. These are the closest the template layer can come to enforcement.
3. **Re-frames the language.** The Session End table in the template now says "Update relevant docs alongside code changes" with an inline note that this is documentation-only unless the host adds enforcement.

If you are adopting Product Pilot and expect the harness to enforce session-start reads or session-end doc updates, you should plan to add the hooks yourself.
