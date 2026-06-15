#!/usr/bin/env bash
# Ryzoner/agent_skills - installer (Linux/macOS)
# Skachivayet arkhiv repozitoriya i ustanavlivayet vse skilly v ~/.agents/skills/
# Idempotentnyy: perezapisyvaet sushchestvuyushchie papki skilov.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/Ryzoner/agent_skills"
REPO_TAR="$REPO_URL/archive/refs/heads/main.tar.gz"

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}  Ryzoner/agent_skills installer${NC}"
echo -e "${CYAN}  Vse skilly + ExampleSubagents${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""

HOME_DIR="$HOME"
SKILLS_DEST="$HOME_DIR/.agents/skills"
EXAMPLES_DEST="$HOME_DIR/.agents/ExampleSubagents"

echo -e "${YELLOW}[~] Domashnyaya direktoriya:${NC} $HOME_DIR"
echo -e "${YELLOW}[~] Kuda:${NC} $SKILLS_DEST"
echo ""

echo -e "${YELLOW}[1] Sozdayu direktorii...${NC}"
mkdir -p "$SKILLS_DEST" "$EXAMPLES_DEST" "$HOME_DIR/.myskills/skills" "$HOME_DIR/.notes/INBOX"
echo -e "    ${GREEN}[OK]${NC} ~/.agents/skills/"
echo -e "    ${GREEN}[OK]${NC} ~/.agents/ExampleSubagents/"
echo -e "    ${GREEN}[OK]${NC} ~/.myskills/skills/"
echo -e "    ${GREEN}[OK]${NC} ~/.notes/INBOX/"
echo ""

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "${YELLOW}[2] Skachivayu ${REPO_URL}...${NC}"
if ! curl -fsSL "$REPO_TAR" -o "$TMPDIR/repo.tar.gz"; then
    echo -e "    ${RED}[X] Oshibka skachivaniya. Prover'te internet.${NC}"
    exit 1
fi

echo -e "${YELLOW}[3] Raspakovyvayu...${NC}"
tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"
REPO_DIR=$(find "$TMPDIR" -maxdepth 1 -type d \( -name "agent_skills-*" -o -name "main" \) | head -1)
if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR/.agents/skills" ]; then
    echo -e "    ${RED}[X] Ne nashyol .agents/skills/ v arkhive.${NC}"
    exit 1
fi

echo -e "${YELLOW}[4] Kopiruyu skilly...${NC}"
copied=0
for skill_dir in "$REPO_DIR/.agents/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    [ "$skill_name" = ".template" ] && continue
    rm -rf "$SKILLS_DEST/$skill_name"
    cp -r "$skill_dir" "$SKILLS_DEST/$skill_name"
    copied=$((copied + 1))
done
echo -e "    ${GREEN}[OK]${NC} Skopirovano: $copied skilov"

echo -e "${YELLOW}[5] Kopiruyu ExampleSubagents...${NC}"
if [ -d "$REPO_DIR/.agents/ExampleSubagents" ]; then
    for item in "$REPO_DIR/.agents/ExampleSubagents"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        [ "$name" = "README.md" ] && continue
        cp -r "$item" "$EXAMPLES_DEST/$name"
    done
    examples_count=$(ls -1 "$EXAMPLES_DEST" 2>/dev/null | wc -l)
    echo -e "    ${GREEN}[OK]${NC} Primerov agentov: $examples_count"
fi

echo -e "${YELLOW}[6] Proveryayu npm-zavisimosti skilov...${NC}"
if command -v npm >/dev/null 2>&1; then
    for pkg_dir in "$SKILLS_DEST"/*/; do
        [ -d "$pkg_dir" ] || continue
        if [ -f "$pkg_dir/package.json" ] && [ ! -d "$pkg_dir/node_modules" ]; then
            skill_name=$(basename "$pkg_dir")
            echo -e "    ${YELLOW}-> $skill_name (npm install)${NC}"
            if (cd "$pkg_dir" && npm install --no-audit --no-fund --silent 2>/dev/null); then
                echo -e "       ${GREEN}[OK]${NC} $skill_name gotov"
            else
                echo -e "       ${YELLOW}[!]${NC} $skill_name: npm install ne udalsya (skill rabotaet i bez zavisimostey)"
            fi
        fi
    done
else
    echo -e "    ${YELLOW}[!]${NC} npm ne nayden - propuskayu (skilly rabotayut i bez zavisimostey)"
fi

echo ""
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}  [OK] Ustanovka zavershena!${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""
echo -e "${GREEN}Ustanovleno:${NC}"
echo -e "  Skilly            -> $SKILLS_DEST"
echo -e "  ExampleSubagents  -> $EXAMPLES_DEST"
echo -e "  User Skills       -> $HOME_DIR/.myskills/skills"
echo -e "  Notes INBOX       -> $HOME_DIR/.notes/INBOX"
echo ""
echo -e "${YELLOW}Sleduyushchie shagi:${NC}"
echo -e "  1. Otkroyte vash AI-agent (Codex, Claude, Qwen, Cursor...)"
echo -e "  2. Agent podkhvatit skilly iz ~/.agents/skills/"
echo -e "  3. Ili skazhite agentu: «pokazhi skilly iz ~/.agents/skills/»"
echo ""
echo -e "${CYAN}[i] Repozitoriy: ${REPO_URL}${NC}"
