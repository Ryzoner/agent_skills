#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/spec-init.sh [--root <path>] [--force] [--dry-run] <spec-name>

Options:
  --root <path>   Project root directory (default: current directory)
  --force         Overwrite existing spec files
  --dry-run       Print planned actions without writing files
  --help          Show this help
EOF
}

detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

normalize_root_path() {
  local in_path="$1"
  local normalized="$in_path"

  # Convert "C:\foo\bar" to "C:/foo/bar" for shell handling.
  if [[ "$normalized" =~ ^[A-Za-z]:\\ ]]; then
    normalized="${normalized//\\//}"
  fi

  # Convert Windows-style path to POSIX path when cygpath is available.
  if command -v cygpath >/dev/null 2>&1 && [[ "$normalized" =~ ^[A-Za-z]:/ ]]; then
    normalized="$(cygpath -u "$normalized")"
  fi

  printf "%s" "$normalized"
}

resolve_abs_path() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p" 2>/dev/null || true
    return
  fi

  (
    cd "$p" 2>/dev/null && pwd -P
  ) || true
}

write_if_needed() {
  local path="$1"

  if [[ -e "$path" && "$FORCE" -ne 1 ]]; then
    echo "SKIP  $path (exists)"
    cat >/dev/null
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -e "$path" ]]; then
      echo "PLAN  overwrite $path"
    else
      echo "PLAN  create $path"
    fi
    cat >/dev/null
    return
  fi

  mkdir -p "$(dirname "$path")"
  cat >"$path"
  echo "WRITE $path"
}

ROOT="."
FORCE=0
DRY_RUN=0
SPEC_NAME_RAW=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -lt 2 ]] && { echo "ERROR: --root requires a path" >&2; exit 2; }
      ROOT="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$SPEC_NAME_RAW" ]]; then
        echo "ERROR: unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      SPEC_NAME_RAW="$1"
      shift
      ;;
  esac
done

if [[ -z "$SPEC_NAME_RAW" ]]; then
  usage >&2
  echo "Example: scripts/spec-init.sh payments-webhook" >&2
  exit 2
fi

# Normalize to kebab-case ASCII: lower, non-alnum -> '-', collapse dashes.
SPEC_NAME="$(
  printf '%s' "$SPEC_NAME_RAW" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
)"

if [[ -z "$SPEC_NAME" ]]; then
  echo "ERROR: spec-name '$SPEC_NAME_RAW' normalizes to empty (expected [a-z0-9-])." >&2
  exit 2
fi

ROOT="$(normalize_root_path "$ROOT")"
OS_FAMILY="$(detect_os)"

if [[ ! -d "$ROOT" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "PLAN  create root dir $ROOT"
  else
    mkdir -p "$ROOT"
    echo "DIR   $ROOT"
  fi
fi

ROOT_ABS="$(resolve_abs_path "$ROOT")"
if [[ -z "$ROOT_ABS" ]]; then
  echo "ERROR: failed to resolve root path: $ROOT" >&2
  exit 2
fi

SPEC_DIR="$ROOT_ABS/.kiro/specs/$SPEC_NAME"
if [[ "$DRY_RUN" -eq 1 ]]; then
  if [[ -d "$SPEC_DIR" ]]; then
    echo "PLAN  keep dir $SPEC_DIR"
  else
    echo "PLAN  create dir $SPEC_DIR"
  fi
else
  mkdir -p "$SPEC_DIR"
  echo "DIR   $SPEC_DIR"
fi

echo "OS    $OS_FAMILY"
echo "ROOT  $ROOT_ABS"
echo "SPEC  $SPEC_NAME"

write_if_needed "$SPEC_DIR/design.md" <<EOF
# Design Document: $SPEC_NAME_RAW

## Overview

TODO: 1-3 абзаца, что строим и зачем.

## Architecture

### High-Level Architecture

TODO: диаграмма высокого уровня.

\`\`\`mermaid
graph TB
  A[TODO] --> B[TODO]
\`\`\`

### Component Architecture

TODO: список компонентов и их роли.

## Components and Interfaces

1. **TODO: Component_Name**
   - Responsibilities: TODO
   - Inputs: TODO
   - Outputs: TODO
   - Interfaces: TODO

## Data/Control Flows

TODO: ключевые сценарии (как данные/события проходят через систему).

## Configuration & Secrets

TODO: env vars, секреты, где хранятся.

## Error Handling & Logging

TODO: стратегия ошибок (retry/timeouts), логирование, уровни, корреляция.

## Constraints / Decisions

TODO: важные ограничения и принятые решения.
EOF

write_if_needed "$SPEC_DIR/requirements.md" <<EOF
# Requirements Document

## Introduction

TODO: цель и границы спецификации "$SPEC_NAME_RAW".

## Glossary

- **TODO_Term**: TODO definition

## Requirements

### Requirement 1: TODO short name

**User Story:** As a TODO role, I want TODO, so that TODO.

#### Acceptance Criteria

1. WHEN TODO, THE TODO_Component SHALL TODO
2. WHEN TODO, THE TODO_Component SHALL TODO

## Testing in CI/CD

### Pre-merge Testing

- TODO

### Post-merge Testing

- TODO

### Manual Testing Checklist

- TODO
EOF

write_if_needed "$SPEC_DIR/tasks.md" <<EOF
# План реализации: $SPEC_NAME_RAW

## Обзор

TODO: 1-2 абзаца.

## Задачи

- [ ] 1. TODO: первая задача
  - [ ] 1.1 TODO: подзадача
    - _Requirements: 1.1_
  - [ ] 1.2 TODO: подзадача*
    - _Requirements: 1.2_

- [ ] 2. Контрольная точка - TODO
  - Убедиться, что все тесты проходят, спросить пользователя при необходимости.

## Примечания

- Задачи с \`*\` опциональны и могут быть пропущены для быстрого MVP
- Каждая задача ссылается на требования для трассируемости
- Контрольные точки обеспечивают поэтапную валидацию
- Property-тесты проверяют универсальные свойства корректности
- Unit-тесты проверяют конкретные примеры и крайние случаи
- Весь TypeScript-код должен следовать best practices и использовать strict mode
- Используй аннотации типов повсеместно для качества кода
- AWS credentials должны храниться в GitHub Secrets, никогда в коде
EOF

cat <<EOF

Next:
- Edit:
  - $SPEC_DIR/design.md
  - $SPEC_DIR/requirements.md
  - $SPEC_DIR/tasks.md
EOF
