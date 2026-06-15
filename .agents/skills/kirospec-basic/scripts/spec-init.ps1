#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

function Show-Usage {
  @"
Usage: scripts/spec-init.ps1 [--root <path>] [--force] [--dry-run] <spec-name>

Options:
  --root <path>   Project root directory (default: current directory)
  --force         Overwrite existing spec files
  --dry-run       Print planned actions without writing files
  --help          Show this help
"@
}

function Get-OsFamily {
  if ($IsWindows) { return "windows" }
  if ($IsMacOS) { return "macos" }
  if ($IsLinux) { return "linux" }
  return "unknown"
}

function Write-Utf8Text {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )
  if ($PSVersionTable.PSVersion.Major -ge 6) {
    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8NoBOM
  } else {
    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8
  }
}

function Write-FileSmart {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content,
    [Parameter(Mandatory = $true)][bool]$Force,
    [Parameter(Mandatory = $true)][bool]$DryRun
  )

  if ((Test-Path -LiteralPath $Path -PathType Leaf) -and (-not $Force)) {
    Write-Output "SKIP  $Path (exists)"
    return
  }

  if ($DryRun) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      Write-Output "PLAN  overwrite $Path"
    } else {
      Write-Output "PLAN  create $Path"
    }
    return
  }

  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  Write-Utf8Text -Path $Path -Content $Content
  Write-Output "WRITE $Path"
}

$Root = "."
$Force = $false
$DryRun = $false
$ShowHelp = $false
$SpecNameRaw = $null

for ($i = 0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    "--root" {
      if ($i + 1 -ge $args.Count) { throw "ERROR: --root requires a path" }
      $i++
      $Root = $args[$i]
    }
    "--force" {
      $Force = $true
    }
    "--dry-run" {
      $DryRun = $true
    }
    "--help" {
      $ShowHelp = $true
    }
    default {
      if ($args[$i].StartsWith("-")) {
        throw "ERROR: unknown option: $($args[$i])"
      }
      if ($null -ne $SpecNameRaw) {
        throw "ERROR: unexpected extra argument: $($args[$i])"
      }
      $SpecNameRaw = $args[$i]
    }
  }
}

if ($ShowHelp) {
  Show-Usage
  exit 0
}

if ([string]::IsNullOrWhiteSpace($SpecNameRaw)) {
  Show-Usage
  Write-Error "Example: scripts/spec-init.ps1 payments-webhook"
  exit 2
}

$SpecName = $SpecNameRaw.ToLowerInvariant() `
  -replace '[^a-z0-9]+', '-' `
  -replace '^-+', '' `
  -replace '-+$', '' `
  -replace '-{2,}', '-'

if ([string]::IsNullOrWhiteSpace($SpecName)) {
  Write-Error "ERROR: spec-name '$SpecNameRaw' normalizes to empty (expected [a-z0-9-])."
  exit 2
}

$expandedRoot = [Environment]::ExpandEnvironmentVariables($Root)
if (-not (Test-Path -LiteralPath $expandedRoot -PathType Container)) {
  if ($DryRun) {
    Write-Output "PLAN  create root dir $expandedRoot"
  } else {
    New-Item -ItemType Directory -Path $expandedRoot -Force | Out-Null
    Write-Output "DIR   $expandedRoot"
  }
}

$rootAbs = (Resolve-Path -LiteralPath $expandedRoot).Path
$specDir = Join-Path $rootAbs ".kiro/specs/$SpecName"

if ($DryRun) {
  if (Test-Path -LiteralPath $specDir -PathType Container) {
    Write-Output "PLAN  keep dir $specDir"
  } else {
    Write-Output "PLAN  create dir $specDir"
  }
} else {
  New-Item -ItemType Directory -Path $specDir -Force | Out-Null
  Write-Output "DIR   $specDir"
}

Write-Output "OS    $(Get-OsFamily)"
Write-Output "ROOT  $rootAbs"
Write-Output "SPEC  $SpecName"

$design = @"
# Design Document: $SpecNameRaw

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
"@

$requirements = @"
# Requirements Document

## Introduction

TODO: цель и границы спецификации "$SpecNameRaw".

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
"@

$tasks = @"
# План реализации: $SpecNameRaw

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

- Задачи с `*` опциональны и могут быть пропущены для быстрого MVP
- Каждая задача ссылается на требования для трассируемости
- Контрольные точки обеспечивают поэтапную валидацию
- Property-тесты проверяют универсальные свойства корректности
- Unit-тесты проверяют конкретные примеры и крайние случаи
- Весь TypeScript-код должен следовать best practices и использовать strict mode
- Используй аннотации типов повсеместно для качества кода
- AWS credentials должны храниться в GitHub Secrets, никогда в коде
"@

Write-FileSmart -Path (Join-Path $specDir "design.md") -Content $design -Force $Force -DryRun $DryRun
Write-FileSmart -Path (Join-Path $specDir "requirements.md") -Content $requirements -Force $Force -DryRun $DryRun
Write-FileSmart -Path (Join-Path $specDir "tasks.md") -Content $tasks -Force $Force -DryRun $DryRun

Write-Output ""
Write-Output "Next:"
Write-Output "- Edit:"
Write-Output "  - $specDir/design.md"
Write-Output "  - $specDir/requirements.md"
Write-Output "  - $specDir/tasks.md"
