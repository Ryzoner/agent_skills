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

# [6] npm install dlya skilov s package.json (archify i dr.)
# Arkhify trebuet Node >= 18 dlya ESM + ajv. Pri starsey versii - preduprezhdaem, no ne blokiruyem.
echo -e "${YELLOW}[6] Proveryayu Node.js + npm-zavisimosti skilov...${NC}"

node_min_ok=1
if command -v node >/dev/null 2>&1; then
    node_major=$(node -v 2>/dev/null | sed -E "s/^v([0-9]+).*//")
    if [ -n "$node_major" ] && [ "$node_major" -lt 18 ] 2>/dev/null; then
        node_min_ok=0
        echo -e "    ${YELLOW}[!]${NC} Node.js v$(node -v | sed "s/^v//") < 18 — nekotorye skilly (archify) mogut ne rabotat'"
    else
        echo -e "    ${GREEN}[OK]${NC} Node.js $(node -v) >= 18"
    fi
else
    node_min_ok=0
    echo -e "    ${YELLOW}[!]${NC} Node.js ne nayden"
fi

if command -v npm >/dev/null 2>&1; then
    for pkg_dir in "$SKILLS_DEST"/*/; do
        [ -d "$pkg_dir" ] || continue
        if [ -f "$pkg_dir/package.json" ]; then
            skill_name=$(basename "$pkg_dir")
            if [ -d "$pkg_dir/node_modules" ]; then
                echo -e "    ${GREEN}[OK]${NC} $skill_name: node_modules uzhe est (propuskayu)"
                continue
            fi
            echo -e "    ${YELLOW}-> $skill_name (npm install)${NC}"
            # Bez --silent chtoby videt oshibki, no 2>&1 > log chtoby ne zasoryat' konsol
            install_log="$TMPDIR/npm-install-$skill_name.log"
            if (cd "$pkg_dir" && npm install --no-audit --no-fund --loglevel=error 2>"$install_log"); then
                echo -e "       ${GREEN}[OK]${NC} $skill_name gotov (ajv + zavisimosti)"
            else
                echo -e "       ${YELLOW}[!]${NC} $skill_name: npm install ne udalsya (prover'te log nizhe)"
                echo -e "       Log: $install_log"
                sed "s/^/         /" "$install_log" | head -5
            fi
        fi
    done
else
    echo -e "    ${YELLOW}[!]${NC} npm ne nayden — skilly s package.json (archify) budut rabotat' bez validacii skhem"
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
