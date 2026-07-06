# Product Design Integration

Use this reference when a project has Product Pilot installed and Product Design is available. The goal is to make the two systems cooperate without duplicating ownership.

## Ownership Boundary

| System | Owns | Does not own |
|--------|------|--------------|
| Product Pilot | Product truth: phase, active milestone, blockers, target users, metrics, principles, shipped work, and docs to update | Visual exploration, screen critique, prototype implementation, design QA, or deployment |
| Product Design | Design execution: research, audits, ideation, prototypes, redesigns, clones, design QA, and sharing | Product-doc truth, milestone advancement, metric claims, or roadmap updates |

## Default Handoff

When a user asks for UX research, a product-flow audit, visual ideation, an app or screen design, redesign, clone, prototype, implementation from URL/image/Figma/code, design QA, or prototype sharing:

1. Read `PRODUCT_PILOT.md` first.
2. Pull the minimum Product Pilot facts needed for the design brief: current phase, active milestone, top blocker, metrics at risk, target users, and product principles. For Full/Lite scope, also pull relevant docs from the Product Docs Index; for Micro scope, use the Pilot only.
3. Route through `product-design:index`.
4. Treat `product-design:index` as a router only. Load the focused Product Design skill that matches the request.
5. Run Product Design user-context preflight when available.
6. Keep Product Pilot update discipline after the design work. If the design work changes product direction, scope, research, roadmap, features, metrics, or shipped UI, run Product Pilot Update Mode.

## Non-Negotiable Gates

- For new UI, prototype, redesign, or build work with no URL, screenshot, Figma frame, mockup, source image, or existing code target: do not scaffold, edit files, or start a server.
- A confirmed design brief is not a visual target.
- After brief confirmation, generate exactly three visual options and wait for the user to choose one before implementation.
- User-facing audits use Product Design `audit`, not `design-qa`.
- Design QA is only for comparing a coded prototype or build against a source visual after both exist.
- Product Pilot docs should record product outcomes, not raw design commentary. Keep screenshots, audit artifacts, and prototype-specific notes separate unless they change product strategy.

## Session-End Updates

After Product Design work, update Product Pilot docs only when the work changes durable product truth:

| Change from Product Design work | Update |
|---------------------------------|--------|
| New validated user insight | `USER_RESEARCH.md` |
| Feature shipped or materially redesigned | `FEATURE_INVENTORY.md` and `PRODUCT_PILOT.md` Recent Shipped |
| Milestone scope or priority changed | `ROADMAP.md` and active milestone notes |
| Metric target or observed metric changed | `METRICS_AND_OKRS.md` and Metrics Snapshot |
| Blocker resolved or new blocker found | `PRODUCT_PILOT.md` What's Blocking Ship |
| Product direction changed | `PRODUCT_OVERVIEW.md`, `ROADMAP.md`, and Decision Pending/Decision Log |

When no durable product truth changed, leave Product Pilot docs alone and report the design artifact path or prototype URL in the normal handoff.
