#!/usr/bin/env bash
# ==============================================================================
# TheCouncil: Universal AI Coding Agent Skill Installer
# ==============================================================================
# Installs TheCouncil's 18 engineering skills and Chancellor router into
# any AI coding assistant: Claude Code, Antigravity CLI, Cursor, Windsurf,
# Aider, GitHub Copilot, Cline/Roo Code, and custom agent environments.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
MANIFEST_FILE="${SCRIPT_DIR}/AGENT_MANIFEST.md"
REGISTRY_FILE="${SKILLS_DIR}/registry.json"

# ANSI Colors
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# Default configuration
TARGET_CLAUDE=false
TARGET_ANTIGRAVITY=false
TARGET_CURSOR=false
TARGET_WINDSURF=false
TARGET_AIDER=false
TARGET_COPILOT=false
TARGET_CLINE=false
INSTALL_ALL=false
MODE_GLOBAL=true
USE_SYMLINK=true
UNINSTALL=false
VERIFY=false
PREFIX=""

print_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║                       THE COUNCIL                        ║"
    echo "  ║        Universal AI Coding Agent Skill Installer         ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

usage() {
    print_banner
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

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
  --prefix <str>   Prefix skill names (e.g., --prefix council- -> council-antirez-pragmatic-c)
  --verify         Verify active skills across detected agents
  --uninstall      Remove installed skills from target agent(s)
  -h, --help       Show this help message

EXAMPLES:
  # Auto-detect and install for all agents on this system:
  ./scripts/install.sh --all

  # Install into Claude Code globally:
  ./scripts/install.sh --claude --global

  # Install into Antigravity CLI globally:
  ./scripts/install.sh --antigravity

  # Install into current project for Cursor and Windsurf:
  ./scripts/install.sh --cursor --windsurf --local

  # Verify existing installation:
  ./scripts/install.sh --verify
EOF
    exit 0
}

# Parse CLI arguments
if [ $# -eq 0 ]; then
    INSTALL_ALL=true
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude) TARGET_CLAUDE=true; shift ;;
        --antigravity|--gemini|--agy) TARGET_ANTIGRAVITY=true; shift ;;
        --cursor) TARGET_CURSOR=true; shift ;;
        --windsurf) TARGET_WINDSURF=true; shift ;;
        --cline|--roo) TARGET_CLINE=true; shift ;;
        --aider) TARGET_AIDER=true; shift ;;
        --copilot) TARGET_COPILOT=true; shift ;;
        --all) INSTALL_ALL=true; shift ;;
        --global) MODE_GLOBAL=true; shift ;;
        --local) MODE_GLOBAL=false; shift ;;
        --copy) USE_SYMLINK=false; shift ;;
        --prefix) PREFIX="$2"; shift 2 ;;
        --verify) VERIFY=true; shift ;;
        --uninstall) UNINSTALL=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Unknown option: $1${RESET}"; usage ;;
    esac
done

# If --all was selected, auto-detect environments
if [ "$INSTALL_ALL" = true ]; then
    echo -e "${YELLOW}Auto-detecting installed AI coding agents...${RESET}"
    if [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; then
        TARGET_CLAUDE=true
        echo -e "  [x] Detected ${BOLD}Claude Code${RESET}"
    fi
    if [ -d "$HOME/.gemini" ] || command -v agy >/dev/null 2>&1; then
        TARGET_ANTIGRAVITY=true
        echo -e "  [x] Detected ${BOLD}Antigravity CLI / Google Antigravity${RESET}"
    fi
    if [ -d "$PWD/.cursor" ] || [ -f "$PWD/.cursorrules" ] || [ -d "$HOME/.cursor" ]; then
        TARGET_CURSOR=true
        echo -e "  [x] Detected ${BOLD}Cursor IDE${RESET}"
    fi
    if [ -f "$PWD/.windsurfrules" ] || [ -d "$HOME/.codeium" ]; then
        TARGET_WINDSURF=true
        echo -e "  [x] Detected ${BOLD}Windsurf / Codeium${RESET}"
    fi
    if [ -f "$PWD/.clinerules" ] || [ -d "$HOME/.vscode/extensions" ] && ls "$HOME/.vscode/extensions" | grep -qi "cline\|roo" 2>/dev/null; then
        TARGET_CLINE=true
        echo -e "  [x] Detected ${BOLD}Cline / Roo Code${RESET}"
    fi
    if [ -f "$PWD/.aider.conf.yml" ] || command -v aider >/dev/null 2>&1; then
        TARGET_AIDER=true
        echo -e "  [x] Detected ${BOLD}Aider${RESET}"
    fi
    if [ -d "$PWD/.github" ]; then
        TARGET_COPILOT=true
        echo -e "  [x] Detected ${BOLD}GitHub Copilot${RESET} workspace"
    fi

    # Fallback if none detected: install for Claude and Antigravity by default
    if [ "$TARGET_CLAUDE" = false ] && [ "$TARGET_ANTIGRAVITY" = false ] && \
       [ "$TARGET_CURSOR" = false ] && [ "$TARGET_WINDSURF" = false ] && \
       [ "$TARGET_CLINE" = false ] && [ "$TARGET_AIDER" = false ] && [ "$TARGET_COPILOT" = false ]; then
        echo -e "${YELLOW}No specific agent detected. Defaulting to Claude Code & Antigravity CLI.${RESET}"
        TARGET_CLAUDE=true
        TARGET_ANTIGRAVITY=true
    fi
fi

# Collect all skill directories: (name, path)
get_skills() {
    python3 -c "
import json, os
with open('$REGISTRY_FILE') as f:
    reg = json.load(f)
for s in reg['skills']:
    slug = os.path.basename(os.path.dirname(s['path']))
    abs_path = os.path.abspath(os.path.join('$SKILLS_DIR', os.path.dirname(s['path'])))
    print(f'{slug}\t{abs_path}')
"
}

# Link or copy directory
install_skill_dir() {
    local source_dir="$1"
    local dest_dir="$2"
    local skill_name="$3"
    local dest_path="${dest_dir}/${PREFIX}${skill_name}"

    mkdir -p "$dest_dir"

    if [ "$UNINSTALL" = true ]; then
        if [ -L "$dest_path" ] || [ -d "$dest_path" ]; then
            rm -rf "$dest_path"
            echo -e "  ${YELLOW}Removed:${RESET} ${dest_path}"
        fi
        return
    fi

    if [ "$USE_SYMLINK" = true ]; then
        if [ -L "$dest_path" ]; then
            rm -f "$dest_path"
        elif [ -d "$dest_path" ]; then
            rm -rf "$dest_path"
        fi
        ln -s "$source_dir" "$dest_path"
        echo -e "  ${GREEN}✓ Linked:${RESET} ${PREFIX}${skill_name} -> ${source_dir}"
    else
        rm -rf "$dest_path"
        cp -r "$source_dir" "$dest_path"
        echo -e "  ${GREEN}✓ Copied:${RESET} ${PREFIX}${skill_name} -> ${dest_path}"
    fi
}

verify_installation() {
    print_banner
    echo -e "${BOLD}Verifying TheCouncil skills across agents...${RESET}\n"

    local total_expected=19
    local any_found=false
    local checks=(
        "Claude Code Global:$HOME/.claude/skills"
        "Claude Code Local:$PWD/.claude/skills"
        "Antigravity Global:$HOME/.gemini/config/skills"
        "Antigravity Local:$PWD/.gemini/skills"
    )

    for item in "${checks[@]}"; do
        local name="${item%%:*}"
        local path="${item##*:}"
        if [ -d "$path" ]; then
            local count=0
            while IFS=$'\t' read -r slug src; do
                if [ -e "${path}/${PREFIX}${slug}/SKILL.md" ]; then
                    ((count++))
                fi
            done < <(get_skills)
            if [ "$count" -gt 0 ]; then
                echo -e "  ${GREEN}[OK]${RESET} ${name}: ${BOLD}${count}/${total_expected}${RESET} skills active at ${path}"
                any_found=true
            fi
        fi
    done

    # Check rule files
    if [ -f "$PWD/.cursor/rules/the-council.mdc" ]; then
        echo -e "  ${GREEN}[OK]${RESET} Cursor Rule File: active at .cursor/rules/the-council.mdc"
        any_found=true
    fi
    if [ -f "$PWD/.windsurfrules" ] && grep -q "TheCouncil" "$PWD/.windsurfrules" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${RESET} Windsurf Rule File: active at .windsurfrules"
        any_found=true
    fi
    if [ -f "$PWD/.clinerules" ] && grep -q "TheCouncil" "$PWD/.clinerules" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${RESET} Cline / Roo Code: active at .clinerules"
        any_found=true
    fi
    if [ -f "$PWD/.github/copilot-instructions.md" ] && grep -q "TheCouncil" "$PWD/.github/copilot-instructions.md" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${RESET} GitHub Copilot: active at .github/copilot-instructions.md"
        any_found=true
    fi
    if [ -f "$PWD/.aider.conf.yml" ] && grep -q "AGENT_MANIFEST.md" "$PWD/.aider.conf.yml" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${RESET} Aider: active in .aider.conf.yml"
        any_found=true
    fi

    if [ "$any_found" = false ]; then
        echo -e "  ${YELLOW}No active skills or agent configurations detected.${RESET}"
        echo -e "  Run ${BOLD}./scripts/install.sh --claude${RESET} (or ${BOLD}--antigravity${RESET}, ${BOLD}--cursor${RESET}, ${BOLD}--all${RESET}) to install."
    fi
    echo ""
    exit 0
}

if [ "$VERIFY" = true ]; then
    verify_installation
fi

print_banner

# ------------------------------------------------------------------------------
# 1. Claude Code
# ------------------------------------------------------------------------------
if [ "$TARGET_CLAUDE" = true ]; then
    local_or_global="global"
    if [ "$MODE_GLOBAL" = true ]; then
        TARGET_DIR="$HOME/.claude/skills"
    else
        TARGET_DIR="$PWD/.claude/skills"
        local_or_global="local"
    fi

    echo -e "${BOLD}${BLUE}Installing to Claude Code (${local_or_global}: ${TARGET_DIR})...${RESET}"
    while IFS=$'\t' read -r slug src; do
        install_skill_dir "$src" "$TARGET_DIR" "$slug"
    done < <(get_skills)
    echo -e "${GREEN}Claude Code installation complete!${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 2. Antigravity CLI / Google Antigravity (AGY)
# ------------------------------------------------------------------------------
if [ "$TARGET_ANTIGRAVITY" = true ]; then
    local_or_global="global"
    if [ "$MODE_GLOBAL" = true ]; then
        TARGET_DIR="$HOME/.gemini/config/skills"
    else
        TARGET_DIR="$PWD/.gemini/skills"
        local_or_global="local"
    fi

    echo -e "${BOLD}${BLUE}Installing to Antigravity CLI (${local_or_global}: ${TARGET_DIR})...${RESET}"
    while IFS=$'\t' read -r slug src; do
        install_skill_dir "$src" "$TARGET_DIR" "$slug"
    done < <(get_skills)
    echo -e "${GREEN}Antigravity CLI installation complete!${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 3. Cursor
# ------------------------------------------------------------------------------
if [ "$TARGET_CURSOR" = true ]; then
    echo -e "${BOLD}${BLUE}Configuring Cursor IDE...${RESET}"
    CURSOR_RULE_DIR="$PWD/.cursor/rules"
    CURSOR_RULE_FILE="$CURSOR_RULE_DIR/the-council.mdc"

    if [ "$UNINSTALL" = true ]; then
        rm -f "$CURSOR_RULE_FILE"
        echo -e "  ${YELLOW}Removed:${RESET} $CURSOR_RULE_FILE"
    else
        mkdir -p "$CURSOR_RULE_DIR"
        cat << 'EOF' > "$CURSOR_RULE_FILE"
---
description: "TheCouncil: 18 Dialectic Engineering Lenses & High-Constraint Skills"
globs: ["*"]
alwaysApply: true
---

# TheCouncil System Directives

This project is governed by TheCouncil engineering skills repository.
When reviewing, designing, or refactoring code:

1. Consult `skills/registry.json` for active triggers and conflict matrices.
2. Comply strictly with `AGENT_MANIFEST.md`.
3. In case of architectural dilemmas, invoke the Chancellor router (`router/ask-council`) or run a Dialectic Tribunal.
EOF
        echo -e "  ${GREEN}✓ Created:${RESET} $CURSOR_RULE_FILE"
    fi
    echo -e "${GREEN}Cursor configuration complete!${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 4. Windsurf / Codeium
# ------------------------------------------------------------------------------
if [ "$TARGET_WINDSURF" = true ]; then
    echo -e "${BOLD}${BLUE}Configuring Windsurf...${RESET}"
    WINDSURF_FILE="$PWD/.windsurfrules"

    if [ "$UNINSTALL" = true ]; then
        if [ -f "$WINDSURF_FILE" ]; then
            sed -i '/# THE COUNCIL DIRECTIVES START/,/# THE COUNCIL DIRECTIVES END/d' "$WINDSURF_FILE" || true
            echo -e "  ${YELLOW}Removed TheCouncil directives from:${RESET} $WINDSURF_FILE"
        fi
    else
        if ! grep -q "THE COUNCIL DIRECTIVES START" "$WINDSURF_FILE" 2>/dev/null; then
            cat << 'EOF' >> "$WINDSURF_FILE"

# THE COUNCIL DIRECTIVES START
# Governed by TheCouncil (18 Engineering Skills & Invariants)
# Reference: AGENT_MANIFEST.md and skills/registry.json
# Invoke /ask-council for interactive lens selection and dialectic tribunals.
# THE COUNCIL DIRECTIVES END
EOF
            echo -e "  ${GREEN}✓ Appended directives to:${RESET} $WINDSURF_FILE"
        else
            echo -e "  ${YELLOW}Already configured in:${RESET} $WINDSURF_FILE"
        fi
    fi
    echo -e "${GREEN}Windsurf configuration complete!${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 5. Cline / Roo Code
# ------------------------------------------------------------------------------
if [ "$TARGET_CLINE" = true ]; then
    echo -e "${BOLD}${BLUE}Configuring Cline / Roo Code...${RESET}"
    CLINE_FILE="$PWD/.clinerules"

    if [ "$UNINSTALL" = true ]; then
        if [ -f "$CLINE_FILE" ]; then
            sed -i '/# THE COUNCIL DIRECTIVES START/,/# THE COUNCIL DIRECTIVES END/d' "$CLINE_FILE" || true
            echo -e "  ${YELLOW}Removed TheCouncil directives from:${RESET} $CLINE_FILE"
        fi
    else
        if ! grep -q "THE COUNCIL DIRECTIVES START" "$CLINE_FILE" 2>/dev/null; then
            cat << 'EOF' >> "$CLINE_FILE"

# THE COUNCIL DIRECTIVES START
# Governed by TheCouncil (18 Engineering Skills & Invariants)
# Reference: AGENT_MANIFEST.md and skills/registry.json
# Invoke /ask-council for interactive lens selection and dialectic tribunals.
# THE COUNCIL DIRECTIVES END
EOF
            echo -e "  ${GREEN}✓ Appended directives to:${RESET} $CLINE_FILE"
        else
            echo -e "  ${YELLOW}Already configured in:${RESET} $CLINE_FILE"
        fi
    fi
    echo -e "${GREEN}Cline / Roo Code configuration complete!${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 6. Aider
# ------------------------------------------------------------------------------
if [ "$TARGET_AIDER" = true ]; then
    echo -e "${BOLD}${BLUE}Configuring Aider...${RESET}"
    AIDER_FILE="$PWD/.aider.conf.yml"

    if [ "$UNINSTALL" = true ]; then
        if [ -f "$AIDER_FILE" ]; then
            sed -i '/read:.*AGENT_MANIFEST.md/d' "$AIDER_FILE" || true
            echo -e "  ${YELLOW}Removed TheCouncil from:${RESET} $AIDER_FILE"
        fi
    else
        touch "$AIDER_FILE"
        if ! grep -q "AGENT_MANIFEST.md" "$AIDER_FILE"; then
            echo "read: [AGENT_MANIFEST.md]" >> "$AIDER_FILE"
            echo -e "  ${GREEN}✓ Configured read manifest in:${RESET} $AIDER_FILE"
        else
            echo -e "  ${YELLOW}Already configured in:${RESET} $AIDER_FILE"
        fi
    fi
    echo -e "${GREEN}Aider configuration complete!${RESET}\n"
fi

# ------------------------------------------------------------------------------
# 7. GitHub Copilot
# ------------------------------------------------------------------------------
if [ "$TARGET_COPILOT" = true ]; then
    echo -e "${BOLD}${BLUE}Configuring GitHub Copilot instructions...${RESET}"
    COPILOT_DIR="$PWD/.github"
    COPILOT_FILE="$COPILOT_DIR/copilot-instructions.md"

    if [ "$UNINSTALL" = true ]; then
        if [ -f "$COPILOT_FILE" ]; then
            sed -i '/# TheCouncil Directives/,$d' "$COPILOT_FILE" || true
            echo -e "  ${YELLOW}Cleaned up:${RESET} $COPILOT_FILE"
        fi
    else
        mkdir -p "$COPILOT_DIR"
        cat << 'EOF' >> "$COPILOT_FILE"

# TheCouncil Directives
When generating, refactoring, or reviewing code in this repository:
- Follow the operational constraints defined in `AGENT_MANIFEST.md` and `skills/registry.json`.
- Enforce hard architectural invariants (e.g. Data-Oriented Design on hot-paths, Deep Modules on API boundaries, Parse-Don't-Validate on input).
EOF
        echo -e "  ${GREEN}✓ Configured:${RESET} $COPILOT_FILE"
    fi
    echo -e "${GREEN}GitHub Copilot configuration complete!${RESET}\n"
fi

echo -e "${BOLD}${GREEN}✔ Installation completed successfully!${RESET}"
echo -e "Run ${BOLD}./scripts/install.sh --verify${RESET} to check the status of all active skills."
