---
name: add-lens
description: Add a new engineering lens (skill) to TheCouncil and register it everywhere it must appear.
disable-model-invocation: true
argument-hint: "<category>/<slug> <author name>"
---

Add the lens `$ARGUMENTS`. Categories in use: architecture, distributed, formal, performance, resilience, security, state, systems, types, router.

1. Read one existing `skills/<category>/*/SKILL.md` in the same category and match its structure, tone and length.
2. Create `skills/<category>/<slug>/SKILL.md`. Required frontmatter: `name` (equals the directory name), `description`, `triggers` (JSON list), `conflicts_with` (JSON list of `category/slug`), `primary_sources` (title + url, real sources only). Required sections, in order: an `**Apply**` paragraph copied verbatim from a sibling lens (directly under the H1), then Core Philosophy & Deliberate Rejections, Hard Implementation Rules, Code Review Checklist, Canonical Idiom. Write `description` as the lens's leading concept followed by `Use when ...` branches.
3. Register it:
   - `.claude-plugin/plugin.json`: add `./skills/<category>/<slug>` to `skills`, keep alphabetical order.
   - `skills/registry.json`: add an entry to `skills` with `name`, `path`, `category`, `author`, and the same `triggers`, `conflicts_with`, `primary_sources` as the SKILL.md.
   - `skills/registry.json` `conflict_matrix`: add a pair for each real conflict (tension, thesis_a, thesis_b).
   - `README.md`: add a row to the seats table, a line to the layout tree, and the author's works to Primary Engineering Works.
   - Update the seat count ("18") in README, INSTALL.md, `package.json`, `plugin.json`, `gemini-extension.json`, `.claude-plugin/*.json` and `registry.json` descriptions.
   - If an existing lens conflicts with the new one, add the new slug to that lens's `conflicts_with` too.
4. Run `python3 scripts/check-manifests.py` and fix every error. Report warnings you did not fix.

Cite only sources you have verified. Write plain prose.
