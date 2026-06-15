#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: spec-init-undo.sh [--root <path>] [--dry-run] <spec-name>

Options:
  --root <path>   Project root directory (default: current directory)
  --dry-run       Print planned action without deleting files
  --help          Show this help
USAGE
}

ROOT="."
DRY_RUN=0
SPEC_NAME_RAW=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -lt 2 ]] && { echo "ERROR: --root requires a path" >&2; exit 2; }
      ROOT="$2"
      shift 2
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
      if [[ -n "${SPEC_NAME_RAW}" ]]; then
        echo "ERROR: unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      SPEC_NAME_RAW="$1"
      shift
      ;;
  esac
done

if [[ -z "${SPEC_NAME_RAW}" ]]; then
  usage >&2
  echo "Example: scripts/spec-init-undo.sh payments-webhook" >&2
  exit 2
fi

SPEC_NAME="$(
  printf '%s' "${SPEC_NAME_RAW}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
)"

[[ -n "${SPEC_NAME}" ]] || {
  echo "ERROR: spec-name '${SPEC_NAME_RAW}' normalizes to empty (expected [a-z0-9-])." >&2
  exit 2
}

if command -v realpath >/dev/null 2>&1; then
  ROOT_ABS="$(realpath "${ROOT}")"
else
  ROOT_ABS="$(cd "${ROOT}" && pwd -P)"
fi

SPEC_DIR="${ROOT_ABS}/.kiro/specs/${SPEC_NAME}"

if [[ ! -d "${SPEC_DIR}" ]]; then
  echo "SKIP  ${SPEC_DIR} (not found)"
  exit 0
fi

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "PLAN  delete ${SPEC_DIR}"
  exit 0
fi

rm -rf "${SPEC_DIR}"
echo "DROP  ${SPEC_DIR}"
