# TheCouncil: AI Coding Agent Installation Guide

This guide details how to install, configure, and verify **TheCouncil** (18 pioneering engineering lenses + the Chancellor intent router) across any AI coding assistant or agent framework.

---

## Quick Start (Automated Installer)

The repository provides an automated installer script [`scripts/install.sh`](file:///home/aleemont/TheCouncil/scripts/install.sh) that handles directory scaffolding, symlinking, copy fallbacks, prefixing, and verification.

```bash
# 1. Clone TheCouncil repository (if not already inside)
git clone https://github.com/your-username/TheCouncil.git
cd TheCouncil

# 2. Make installer executable
chmod +x scripts/install.sh

# 3. Auto-detect installed agents and install everywhere:
./scripts/install.sh --all

# 4. Verify installation
./scripts/install.sh --verify
```

---

## Supported AI Coding Agents

| Agent / Tool | Integration Mechanism | Default Target Path |
| :--- | :--- | :--- |
| **Claude Code** (Anthropic) | Native skill directories (`SKILL.md`) | `~/.claude/skills/<skill-slug>` (Global)<br>`.claude/skills/<skill-slug>` (Workspace) |
| **Google Antigravity CLI (AGY)** | Native skill directories (`SKILL.md`) | `~/.gemini/config/skills/<skill-slug>` (Global)<br>`.gemini/skills/<skill-slug>` (Workspace) |
| **Cursor IDE** | MDC rule definition & manifest link | `.cursor/rules/the-council.mdc` |
| **Windsurf IDE (Codeium)** | System rules directive | `.windsurfrules` |
| **Cline / Roo Code** | System instructions | `.clinerules` |
| **Aider** | Auto-read manifest file | `.aider.conf.yml` (`read: [AGENT_MANIFEST.md]`) |
| **GitHub Copilot** | Workspace instructions | `.github/copilot-instructions.md` |
| **Custom / Headless Agents** | Context injection via prompt / manifest | [`AGENT_MANIFEST.md`](file:///home/aleemont/TheCouncil/AGENT_MANIFEST.md) & [`skills/registry.json`](file:///home/aleemont/TheCouncil/skills/registry.json) |

---

## Automated Installation Options

The installer supports granular flags for selecting target agents and installation behavior:

```
Usage: ./scripts/install.sh [OPTIONS]

TARGET AGENTS:
  --claude         Install into Claude Code (~/.claude/skills or .claude/skills)
  --antigravity    Install into Antigravity CLI (~/.gemini/config/skills)
  --cursor         Install into Cursor (.cursor/rules/the-council.mdc)
  --windsurf       Install into Windsurf (.windsurfrules)
  --cline, --roo   Install into Cline / Roo Code (.clinerules)
  --aider          Install into Aider (.aider.conf.yml)
  --copilot        Install into GitHub Copilot (.github/copilot-instructions.md)
  --all            Auto-detect all installed agents and install for all of them

INSTALLATION OPTIONS:
  --global         Install to user global config directory (default)
  --local          Install to current repository/workspace
  --copy           Copy files instead of symlinking (default: symlink)
  --prefix <str>   Prefix skill names (e.g. --prefix council- -> council-muratori-data-oriented)
  --verify         Verify active skills across detected agents
  --uninstall      Remove installed skills from target agent(s)
  -h, --help       Show help message
```

### Common Usage Examples

```bash
# Install globally for Claude Code and Antigravity CLI:
./scripts/install.sh --claude --antigravity --global

# Install into the current project workspace for Claude Code:
./scripts/install.sh --claude --local

# Configure IDE rules for Cursor and Windsurf in the current project:
./scripts/install.sh --cursor --windsurf

# Install with custom naming prefix (prevents collisions with custom skills):
./scripts/install.sh --claude --prefix council-

# Hard copy files (recommended for Docker containers or air-gapped CI/CD):
./scripts/install.sh --claude --copy

# Uninstall TheCouncil from an agent:
./scripts/install.sh --claude --uninstall
```

---

## Symlink vs. Copy: Which Should You Use?

- **Symlink (`--symlink`, Default)**:
  - **Pros**: Any `git pull` in `TheCouncil` instantly updates the skills across all your AI assistants. Zero disk duplication.
  - **Best For**: Local development workstations on Linux, macOS, or WSL2.
- **Copy (`--copy`)**:
  - **Pros**: Self-contained; does not depend on the location of `TheCouncil` repository remaining fixed.
  - **Best For**: Remote Docker containers, CI/CD runners, and Windows environments without symlink privileges enabled.

---

## Manual Installation Guide

If you prefer to configure your agent manually without executing bash scripts, follow the instructions below for your specific tool:

### 1. Claude Code (Anthropic)

Claude Code discovers skills placed in directories containing a `SKILL.md` file.

**Option A: Global Installation (Available across all your projects)**
```bash
mkdir -p ~/.claude/skills
for skill in skills/*/*; do
  slug=$(basename "$skill")
  ln -s "$(pwd)/$skill" "$HOME/.claude/skills/$slug"
done
```

**Option B: Project-Specific Installation (Available only in target project)**
```bash
TARGET_PROJECT="/path/to/your/project"
mkdir -p "$TARGET_PROJECT/.claude/skills"
for skill in skills/*/*; do
  slug=$(basename "$skill")
  ln -s "$(pwd)/$skill" "$TARGET_PROJECT/.claude/skills/$slug"
done
```

---

### 2. Google Antigravity CLI (AGY) / Google Antigravity

Antigravity loads skills from `~/.gemini/config/skills/` (global) or `.gemini/skills/` (workspace).

**Option A: Global Installation**
```bash
mkdir -p ~/.gemini/config/skills
for skill in skills/*/*; do
  slug=$(basename "$skill")
  ln -s "$(pwd)/$skill" "$HOME/.gemini/config/skills/$slug"
done
```

**Option B: Project-Specific Installation**
```bash
TARGET_PROJECT="/path/to/your/project"
mkdir -p "$TARGET_PROJECT/.gemini/skills"
for skill in skills/*/*; do
  slug=$(basename "$skill")
  ln -s "$(pwd)/$skill" "$TARGET_PROJECT/.gemini/skills/$slug"
done
```

---

### 3. Cursor IDE

Cursor operates on `.cursor/rules/*.mdc` files or root `.cursorrules`.

1. Create directory:
   ```bash
   mkdir -p .cursor/rules
   ```
2. Create `.cursor/rules/the-council.mdc`:
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

---

### 4. Windsurf IDE (Codeium)

Windsurf reads instructions from `.windsurfrules` located in the root of the workspace.

Add the following block to `.windsurfrules`:

```markdown
# THE COUNCIL DIRECTIVES START
# Governed by TheCouncil (18 Engineering Skills & Invariants)
# Reference: AGENT_MANIFEST.md and skills/registry.json
# Invoke /ask-council for interactive lens selection and dialectic tribunals.
# THE COUNCIL DIRECTIVES END
```

---

### 5. Cline & Roo Code

Cline and Roo Code read project system directives from `.clinerules`.

Add the following block to `.clinerules`:

```markdown
# THE COUNCIL DIRECTIVES START
# Governed by TheCouncil (18 Engineering Skills & Invariants)
# Reference: AGENT_MANIFEST.md and skills/registry.json
# Invoke /ask-council for interactive lens selection and dialectic tribunals.
# THE COUNCIL DIRECTIVES END
```

---

### 6. Aider

Aider supports auto-loading documentation and manifests via `.aider.conf.yml`.

1. Create or edit `.aider.conf.yml` in your project root:
   ```yaml
   read:
     - AGENT_MANIFEST.md
   ```
2. Symlink or copy [`AGENT_MANIFEST.md`](file:///home/aleemont/TheCouncil/AGENT_MANIFEST.md) and the [`skills/`](file:///home/aleemont/TheCouncil/skills) directory into the repository being edited with Aider.

---

### 7. GitHub Copilot

GitHub Copilot supports workspace custom instructions via `.github/copilot-instructions.md`.

Create `.github/copilot-instructions.md`:

```markdown
# TheCouncil Directives

When generating, refactoring, or reviewing code in this repository:
- Follow the operational constraints defined in `AGENT_MANIFEST.md` and `skills/registry.json`.
- Enforce hard architectural invariants (e.g. Data-Oriented Design on hot-paths, Deep Modules on API boundaries, Parse-Don't-Validate on input boundaries).
- In case of design conflicts, refer to the Dialectic Tribunal matrix in `skills/registry.json`.
```

---

### 8. Custom / Headless / Orchestrated Agents

If you are developing a custom agent pipeline (using LangChain, LangGraph, AutoGen, CrewAI, or direct LLM system prompts):

1. **System Prompt Injection**:
   Include the raw text of [`AGENT_MANIFEST.md`](file:///home/aleemont/TheCouncil/AGENT_MANIFEST.md) in the system prompt.
2. **Dynamic Tool / Skill Retrieval**:
   Load [`skills/registry.json`](file:///home/aleemont/TheCouncil/skills/registry.json) into your agent's retriever. When user queries match keywords in `triggers` or `conflicts_with`, inject the corresponding `SKILL.md` as contextual few-shot instructions into the active context window.

---

## Verifying & Testing Activation

### 1. Verification Script
Run the built-in verifier:
```bash
./scripts/install.sh --verify
```
A healthy output reports the active skill count (19/19) across all configured agents:
```
  [OK] Claude Code Global: 19/19 skills active at /home/user/.claude/skills
  [OK] Antigravity Global: 19/19 skills active at /home/user/.gemini/config/skills
  [OK] Cursor Rule File: active at .cursor/rules/the-council.mdc
```

### 2. Interactive Agent Test
In your agent's chat interface (e.g., Claude Code, Antigravity, Cursor, or Aider), ask:
> *"I have a high-throughput event processing loop in C++ with too many virtual calls. Which Council lens applies?"*

**Expected Behavior**:
The agent should identify the **Casey Muratori (`performance/muratori-data-oriented`)** lens or route via **`router/ask-council`**, citing cache lines, Structure of Arrays (SoA), and rejection of OOP polymorphism in favor of transform functions.

---

## Updating TheCouncil

When new skills or revisions are added to TheCouncil:
- If installed via **symlink** (default): Run `git pull origin main` in the TheCouncil repository. All agents reflect the updates immediately.
- If installed via **copy**: Re-run `./scripts/install.sh --copy` to refresh the target directories.
