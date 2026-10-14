# Product Design Integration

Use this reference when a project has Product Pilot installed and a Product Design skill set is available. The two own different things and must not block each other.

## Ownership Boundary

| System | Owns | Does not own |
|--------|------|--------------|
| Product Pilot | Product truth: phase, ACTIVE milestone, blockers, decisions, shipped work, and which docs are maintained | Visual exploration, screen critique, prototype implementation, design QA, or deployment |
| Product Design | Design execution: research, audits, ideation, prototypes, redesigns, clones, design QA, and sharing | Product-doc truth, milestone advancement, metric claims, or roadmap updates |

## Default Handoff

When a task asks for UX research, a product-flow audit, visual ideation, a screen design, a redesign, a clone, a prototype, implementation from a URL, image, Figma frame, or code, design QA, or prototype sharing:

1. Run `scripts/pilot-banner.sh` or read `PRODUCT_PILOT.md`. Take only what the brief needs: phase, ACTIVE milestone, top blocker, and the product description. Full scope may add target users and principles from the supporting docs.
2. Route through `product-design:index`, which is a router. Load the focused Product Design skill that matches the request.
3. Run the Product Design user-context preflight when available.
4. After the design work, run Product Pilot Reconcile only if durable product truth changed (see Session-End Updates).

## Design Decisions Without Waiting

These replace the earlier "generate three options and wait for the user" gate, which stalled unattended pipelines.

- **No visual target yet** (no URL, screenshot, Figma frame, mockup, or existing code): produce one first. A mockup or prototype generated from the brief is the target. Do not start scaffolding production code before a target exists, and do not wait for a human to supply one.
- **Choosing a direction.** With a human present, show up to three directions, recommend one, and proceed with the recommendation unless they choose otherwise in the same exchange. Unattended, choose one, write the reason as an agent-tier entry in the ROADMAP.md Decision Log, and proceed. A later human choice can reverse it; the work is not lost, the direction changes.
- **Audits.** User-facing audits use the Product Design `audit` skill, not `design-qa`. Design QA compares a coded prototype or build against a source visual once both exist.
- **Research.** Desk research inside a design task is fine. Interviews, surveys, and usability sessions are not added as tasks or gates unless the human asked for them.
- Product Pilot docs record product outcomes, not design commentary. Keep screenshots, audit artifacts, and prototype notes out of the Pilot unless they change the roadmap.

## Session-End Updates

After Product Design work, update Product Pilot docs only when the work changed durable product truth. Lean scope has only the first three rows.

| Change from Product Design work | Update |
|---------------------------------|--------|
| Feature shipped or materially redesigned | `PRODUCT_PILOT.md` Recent Shipped (via reconcile) |
| Milestone scope or priority changed | `ROADMAP.md` and the ACTIVE milestone tasks |
| Blocker resolved or new release blocker found | `PRODUCT_PILOT.md` What's Blocking Ship |
| Product direction changed | `ROADMAP.md` Decision Log; Full scope also `PRODUCT_OVERVIEW.md` |
| New validated user insight | Full scope: `USER_RESEARCH.md` |
| Metric target or observed metric changed | Full scope: `METRICS_AND_OKRS.md` and the Metrics Snapshot |

When no durable product truth changed, leave the Pilot alone and report the design artifact path or prototype URL in the normal handoff.
