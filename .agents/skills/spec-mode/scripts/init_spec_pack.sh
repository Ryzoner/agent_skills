#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <repo-root> <slug>"
  exit 1
fi

repo_root="$1"
slug="$2"
skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
spec_dir="$repo_root/.spec/$slug"

mkdir -p "$spec_dir"

for name in TASK Requirements Design; do
  target="$spec_dir/$name.md"
  if [[ -f "$target" ]]; then
    continue
  fi
  cp "$skill_root/templates/$name.template.md" "$target"
done

echo "created: $spec_dir"
