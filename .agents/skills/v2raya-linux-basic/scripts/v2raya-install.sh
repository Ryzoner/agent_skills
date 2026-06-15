#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  v2raya-install.sh [--distro auto|arch|ubuntu|fedora] [--apply] [--skip-enable] [--skip-status]

Options:
  --distro <name>  Force distro profile. Default: auto (detect from /etc/os-release)
  --apply          Execute commands. By default script only prints plan.
  --skip-enable    Skip "systemctl enable --now v2raya" step.
  --skip-status    Skip "systemctl status v2raya" step.
  -h, --help       Show help.

Examples:
  # Preview only (safe default)
  bash scripts/v2raya-install.sh

  # Force Arch profile preview
  bash scripts/v2raya-install.sh --distro arch

  # Real install for detected distro
  bash scripts/v2raya-install.sh --apply
EOF
}

err() {
  echo "error=$*" >&2
}

DISTRO_OVERRIDE="auto"
APPLY=0
RUN_ENABLE=1
RUN_STATUS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro)
      shift
      DISTRO_OVERRIDE="${1:-}"
      shift || true
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --skip-enable)
      RUN_ENABLE=0
      shift
      ;;
    --skip-status)
      RUN_STATUS=0
      shift
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      err "unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
done

normalize_distro() {
  local value="${1:-}"
  case "${value}" in
    arch|manjaro)
      echo "arch"
      ;;
    ubuntu|debian)
      echo "ubuntu"
      ;;
    fedora|rhel|centos)
      echo "fedora"
      ;;
    *)
      echo ""
      ;;
  esac
}

detect_distro() {
  if [[ "${DISTRO_OVERRIDE}" != "auto" ]]; then
    normalize_distro "${DISTRO_OVERRIDE}"
    return 0
  fi

  if [[ ! -f /etc/os-release ]]; then
    echo ""
    return 0
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  local by_id by_like
  by_id="$(normalize_distro "${ID:-}")"
  [[ -n "${by_id}" ]] && { echo "${by_id}"; return 0; }
  by_like="$(normalize_distro "${ID_LIKE:-}")"
  [[ -n "${by_like}" ]] && { echo "${by_like}"; return 0; }
  echo ""
}

require_bin() {
  local name="$1"
  command -v "${name}" >/dev/null 2>&1 || {
    err "required binary is missing: ${name}"
    exit 1
  }
}

declare -a COMMANDS

build_commands() {
  local distro="$1"
  COMMANDS=()
  case "${distro}" in
    arch)
      COMMANDS+=("yay -S v2raya xray-bin")
      ;;
    ubuntu)
      COMMANDS+=("sudo mkdir -p /etc/apt/keyrings")
      COMMANDS+=("curl -fsSL https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc >/dev/null")
      COMMANDS+=("echo \"deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main\" | sudo tee /etc/apt/sources.list.d/v2raya.list >/dev/null")
      COMMANDS+=("sudo apt update")
      COMMANDS+=("sudo apt install -y v2raya xray")
      ;;
    fedora)
      COMMANDS+=("sudo dnf -y copr enable zhullyb/v2rayA")
      COMMANDS+=("sudo dnf -y install v2raya v2ray")
      ;;
    *)
      err "unsupported distro profile: ${distro}"
      exit 2
      ;;
  esac

  if [[ "${RUN_ENABLE}" -eq 1 ]]; then
    COMMANDS+=("sudo systemctl enable --now v2raya")
  fi
  if [[ "${RUN_STATUS}" -eq 1 ]]; then
    COMMANDS+=("sudo systemctl status v2raya --no-pager")
  fi
}

precheck_apply() {
  local distro="$1"
  require_bin bash
  require_bin sudo
  case "${distro}" in
    arch)
      require_bin yay
      ;;
    ubuntu)
      require_bin curl
      require_bin apt
      ;;
    fedora)
      require_bin dnf
      ;;
  esac
}

print_plan() {
  local distro="$1"
  echo "status=plan"
  echo "mode=$([[ ${APPLY} -eq 1 ]] && echo apply || echo preview)"
  echo "distro=${distro}"
  echo "steps=${#COMMANDS[@]}"
  local i=1
  for cmd in "${COMMANDS[@]}"; do
    echo "step_${i}=${cmd}"
    i=$((i + 1))
  done
  echo "ui_url=http://127.0.0.1:2017"
  echo "note=after_service_use_web_ui_for_system_proxy_tun_routinga_and_outline_keys"
}

run_apply() {
  local i=1
  for cmd in "${COMMANDS[@]}"; do
    echo "run_step=${i} cmd=${cmd}"
    bash -lc "${cmd}"
    i=$((i + 1))
  done
  echo "status=done"
  echo "ui_url=http://127.0.0.1:2017"
}

main() {
  local distro
  distro="$(detect_distro)"
  if [[ -z "${distro}" ]]; then
    err "failed to detect distro profile. Use --distro arch|ubuntu|fedora."
    exit 2
  fi

  build_commands "${distro}"
  print_plan "${distro}"
  if [[ "${APPLY}" -eq 1 ]]; then
    precheck_apply "${distro}"
    run_apply
  fi
}

main "$@"
