# Contributing to Product Pilot

Thanks for your interest in improving Product Pilot!

## How to contribute

1. **Fork** the repo
2. **Create a branch** for your change
3. **Make your changes** (see guidelines below)
4. **Test** by running the skill on a real project
5. **Open a Pull Request** with a clear description of what changed and why

All PRs require review before merge.

## Guidelines

- **Keep templates concise.** Each template has a target line count listed in SKILL.md. Stay within it.
- **Test on a real project.** Copy your modified skill to `~/.claude/skills/product-pilot/` and run it. Verify the generated docs are correct and complete.
- **No breaking changes to PRODUCT_PILOT_TEMPLATE.md without a version bump.** Users depend on the Pilot's structure. If you change section names, ordering, or remove sections, bump the version in SKILL.md.
- **Preserve placeholder conventions.** Templates use `[PLACEHOLDER: ...]` for required fields and `[TODO: ...]` for optional fields. Don't change this convention.
- **Keep the skill generic.** No project-specific content, no hardcoded product names, no assumptions about tech stack.

## What makes a good contribution

- Fixing a template that produces unclear or misleading output
- Adding handling for an edge case the interview doesn't cover
- Improving the Pre-fill Pass to extract more context automatically
- Better examples in SKILL.md
- Documentation improvements

## Questions?

Open an issue and we'll discuss.
