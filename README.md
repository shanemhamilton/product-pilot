[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

# Product Pilot

**Give your AI coding agent product awareness.**

Product Pilot is a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that bootstraps self-maintaining product documentation for any project. It creates a lightweight Product Pilot file that tells your AI agent what phase you're in, what milestone is active, what metrics matter, and what docs to update when work is done. No more repeating product context every session.

## Install

Copy the skill into your Claude Code skills directory:

```bash
cp -r product-pilot ~/.claude/skills/product-pilot
```

Or clone this repo directly:

```bash
git clone https://github.com/shanemhamilton/product-pilot.git ~/.claude/skills/product-pilot
```

## Usage

In Claude Code, say any of:

- "Set up a product pilot"
- "Create product context for my project"
- "Make my agent product-aware"
- `/product-pilot`

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

## Teams Mode

If you have Claude Code agent teams enabled, the skill automatically parallelizes document generation across teammates. This cuts generation time significantly for Full scope. No configuration needed.

## Update Mode

If a Product Pilot already exists, the skill switches to update mode: it asks what changed and updates only the relevant files. Run periodically to keep docs current.

## License

[MIT](LICENSE)
