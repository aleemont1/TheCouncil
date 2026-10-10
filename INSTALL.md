# Installing TheCouncil

TheCouncil is 18 engineering lenses plus the Chancellor router, packaged as Agent Skills and as Claude Code / Antigravity plugins. Install it with `npx`, as a plugin marketplace, or with editor rules.

---

## Method 1: Universal Installation via `npx skills` (Recommended)

Uses the [Agent Skills CLI](https://skills.sh/). It detects installed coding agents (Claude Code, Cursor, Antigravity, Copilot, Codex, etc.) and registers the skills without cloning:

```bash
# Install all 19 skills into your project workspace (auto-detects active agents):
npx skills add aleemont1/TheCouncil

# Install all skills globally (available across all projects on your machine):
npx skills add aleemont1/TheCouncil -g

# Install non-interactively to all detected agents:
npx skills add aleemont1/TheCouncil --all

# List all available Council skills without installing:
npx skills add aleemont1/TheCouncil -l

# Install a specific skill (e.g., Chancellor router or Casey Muratori DOD lens):
npx skills add aleemont1/TheCouncil --skill router/ask-council
npx skills add aleemont1/TheCouncil --skill performance/muratori-data-oriented

# Install specifically for designated agents:
npx skills add aleemont1/TheCouncil --agent claude-code cursor -g
```

---

## Method 2: Claude Code & Codex Plugin Marketplace (Direct GitHub Repo)

The repository ships `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json`, so it can be added as a marketplace in Claude Code and Codex.

### In Claude Code

In an interactive Claude Code session (or Claude Code Desktop app):

```text
/plugin marketplace add aleemont1/TheCouncil
/plugin install the-council@the-council
```

In the Claude Code Desktop app: **+** next to the prompt box → **Plugins** → **Add plugin**.

To uninstall:
```text
/plugin remove the-council
```

### In Codex CLI

```bash
codex plugin marketplace add aleemont1/TheCouncil
codex plugin add the-council@the-council
```

To remove:
```bash
codex plugin remove the-council
```

---

## Method 3: Antigravity CLI / Gemini Extensions (Direct GitHub URL)

The repository ships `gemini-extension.json` and `plugin.json`. Install with the Antigravity CLI (`agy`) or Gemini CLI:

```bash
# Using Antigravity CLI (agy):
agy plugin install https://github.com/aleemont1/TheCouncil

# Or using Gemini CLI:
gemini extensions install https://github.com/aleemont1/TheCouncil
```

To verify the installation:
```bash
agy plugin list
```

To uninstall:
```bash
agy plugin uninstall the-council
```

---

## Method 4: Editor & Workspace Rule Directives

For editors that read workspace rules:

### Cursor IDE
Add `.cursor/rules/the-council.mdc` to your workspace:
```markdown
---
description: "TheCouncil: 18 Dialectic Engineering Lenses & High-Constraint Skills"
globs: ["*"]
alwaysApply: true
---

# TheCouncil System Directives
This repository is governed by TheCouncil engineering skills repository.
When reviewing, designing, or refactoring code:
1. Consult `skills/registry.json` for active triggers and conflict matrices.
2. Comply strictly with `AGENT_MANIFEST.md`.
3. In case of architectural dilemmas, invoke the Chancellor router (`router/ask-council`) or run a Dialectic Tribunal.
```

### Windsurf IDE (Codeium)
Append to `.windsurfrules`:
```markdown
# THE COUNCIL DIRECTIVES START
# Governed by TheCouncil (18 Engineering Skills & Invariants)
# Reference: AGENT_MANIFEST.md and skills/registry.json
# Invoke /ask-council for interactive lens selection and dialectic tribunals.
# THE COUNCIL DIRECTIVES END
```

### Cline & Roo Code
Append to `.clinerules`:
```markdown
# THE COUNCIL DIRECTIVES START
# Governed by TheCouncil (18 Engineering Skills & Invariants)
# Reference: AGENT_MANIFEST.md and skills/registry.json
# Invoke /ask-council for interactive lens selection and dialectic tribunals.
# THE COUNCIL DIRECTIVES END
```

### Aider
In `.aider.conf.yml`:
```yaml
read:
  - AGENT_MANIFEST.md
```

### GitHub Copilot
In `.github/copilot-instructions.md`:
```markdown
# TheCouncil Directives
When generating, refactoring, or reviewing code in this repository:
- Follow the operational constraints defined in `AGENT_MANIFEST.md` and `skills/registry.json`.
- Enforce hard architectural invariants (e.g. Data-Oriented Design on hot-paths, Deep Modules on API boundaries, Parse-Don't-Validate on input boundaries).
```

---

## Offline / Local Installation Utility

To install from a clone (e.g. air-gapped), use [`scripts/install.sh`](./scripts/install.sh):

```bash
# Clone the repository
git clone https://github.com/aleemont1/TheCouncil.git
cd TheCouncil

# Auto-detect all agents and install:
./scripts/install.sh --all

# Or target specific agents:
./scripts/install.sh --claude --global
./scripts/install.sh --antigravity --global
./scripts/install.sh --cursor --windsurf --local

# Verify installed skills:
./scripts/install.sh --verify
```

---

## Verify

After installing, check that your agent sees the skills:

1. **Ask for triage**:
   > *"We are designing a high-throughput network engine in C++ and debating between polymorphic streams and cache-aligned ring buffers. Apply /ask-council."*

2. **Run a Dialectic Tribunal**:
   > *"Run a Dialectic Tribunal on my parser using Casey Muratori (performance/muratori-data-oriented) vs Alexis King (types/king-type-driven-design)."*

3. **Check skill registry**:
   All 18 seats and the Chancellor router are cataloged with triggers and conflict pairs in [`skills/registry.json`](./skills/registry.json).
