#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  outlinectl.sh install --host-id <id> --ssh-host <user@host>
  outlinectl.sh sync-config --host-id <id> [--ssh-host <user@host>]
  outlinectl.sh status --host-id <id> [--ssh-host <user@host>]
  outlinectl.sh keys-list --host-id <id>
  outlinectl.sh keys-create --host-id <id> [--count <n>] [--name-prefix <prefix>] [--start-index <n>] [--bytes <n>] [--print-urls]
  outlinectl.sh key-delete --host-id <id> --id <key-id>
  outlinectl.sh keys-delete --host-id <id> --ids <id1,id2,...>
  outlinectl.sh keys-delete-all --host-id <id> [--keep-ids <id1,id2,...>] --yes
  outlinectl.sh key-limit --host-id <id> --id <key-id> --bytes <n>
  outlinectl.sh key-unlimit --host-id <id> --id <key-id>
  outlinectl.sh show-config --host-id <id>

Options:
  --host-id <id>       Local label for stored manager config
  --ssh-host <target>  SSH target for VPS operations, for example root@<your-vps-ip>
  --count <n>          Number of keys to create (default: 1)
  --name-prefix <p>    Key name prefix (default: outline)
  --start-index <n>    Start index for generated names (default: 1)
  --bytes <n>          Traffic limit in bytes (optional for keys-create, required for key-limit)
  --id <key-id>        Single key id
  --ids <csv>          Comma-separated key ids for keys-delete
  --keep-ids <csv>     Comma-separated ids not to delete in keys-delete-all
  --print-urls         Print access URLs to stdout for keys-create (off by default)
  --yes                Required confirmation for keys-delete-all

Notes:
  - Sensitive files are stored in: ${XDG_CONFIG_HOME:-$HOME/.config}/codex/outline
  - install/sync-config/status can reuse --ssh-host from saved config
EOF
}

outline_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/codex/outline"
ssh_opts=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)

require_cmd() {
  local name="$1"
  command -v "${name}" >/dev/null 2>&1 || {
    echo "Error: '${name}' is required." >&2
    exit 1
  }
}

require_jq() {
  require_cmd jq
}

require_host_id() {
  local host_id="$1"
  [[ -n "${host_id}" ]] || {
    echo "Error: --host-id is required." >&2
    exit 2
  }
}

manager_file() {
  local host_id="$1"
  printf '%s/%s.manager.env' "${outline_dir}" "${host_id}"
}

read_env_key() {
  local key="$1"
  local file="$2"
  [[ -f "${file}" ]] || return 1
  local line
  line="$(grep -m1 -E "^${key}=" "${file}" || true)"
  [[ -n "${line}" ]] || return 1
  printf '%s' "${line#*=}"
}

save_manager_config() {
  local host_id="$1"
  local ssh_host="$2"
  local api_url="$3"
  local cert_sha="$4"
  mkdir -p "${outline_dir}"
  chmod 700 "${outline_dir}" || true
  local file
  file="$(manager_file "${host_id}")"
  {
    echo "HOST_ID=${host_id}"
    echo "SSH_HOST=${ssh_host}"
    echo "API_URL=${api_url}"
    echo "CERT_SHA256=${cert_sha}"
    echo "UPDATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "${file}"
  chmod 600 "${file}" || true
  echo "${file}"
}

load_manager_config() {
  local host_id="$1"
  local file ssh_host api_url cert_sha
  file="$(manager_file "${host_id}")"
  ssh_host="$(read_env_key "SSH_HOST" "${file}" || true)"
  api_url="$(read_env_key "API_URL" "${file}" || true)"
  cert_sha="$(read_env_key "CERT_SHA256" "${file}" || true)"
  [[ -n "${api_url}" && -n "${cert_sha}" ]] || {
    echo "Error: manager config is missing for host '${host_id}'. Run 'install' or 'sync-config' first." >&2
    echo "Expected file: ${file}" >&2
    exit 1
  }
  printf '%s|%s|%s|%s\n' "${file}" "${ssh_host}" "${api_url}" "${cert_sha}"
}

resolve_ssh_host() {
  local host_id="$1"
  local cli_ssh_host="$2"
  if [[ -n "${cli_ssh_host}" ]]; then
    printf '%s' "${cli_ssh_host}"
    return 0
  fi
  local file saved_ssh_host api_url cert_sha
  IFS='|' read -r file saved_ssh_host api_url cert_sha <<< "$(load_manager_config "${host_id}")"
  [[ -n "${saved_ssh_host}" ]] || {
    echo "Error: --ssh-host is required because no SSH target is stored for '${host_id}'." >&2
    exit 2
  }
  printf '%s' "${saved_ssh_host}"
}

remote_exec() {
  local ssh_host="$1"
  local command_text="$2"
  ssh "${ssh_opts[@]}" "${ssh_host}" "${command_text}"
}

extract_manager_json() {
  local raw="$1"
  printf '%s\n' "${raw}" | grep -Eo '\{"apiUrl":"[^"]+","certSha256":"[^"]+"\}' | tail -n 1 || true
}

outline_api() {
  local api_url="$1"
  local method="$2"
  local path="$3"
  local body="${4:-}"
  if [[ -n "${body}" ]]; then
    curl -sk -X "${method}" "${api_url}${path}" -H "Content-Type: application/json" --data "${body}"
  else
    curl -sk -X "${method}" "${api_url}${path}"
  fi
}

cmd_install() {
  local host_id="" ssh_host=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --ssh-host) shift; ssh_host="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for install." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  [[ -n "${ssh_host}" ]] || { echo "Error: --ssh-host is required for install." >&2; exit 2; }
  require_jq

  local output json_line api_url cert_sha cfg_file
  output="$(remote_exec "${ssh_host}" "set -e; curl -sS https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh | bash")"
  json_line="$(extract_manager_json "${output}")"
  [[ -n "${json_line}" ]] || {
    echo "Error: failed to extract Outline manager JSON from install output." >&2
    echo "${output}" >&2
    exit 1
  }
  api_url="$(printf '%s' "${json_line}" | jq -r '.apiUrl')"
  cert_sha="$(printf '%s' "${json_line}" | jq -r '.certSha256')"
  cfg_file="$(save_manager_config "${host_id}" "${ssh_host}" "${api_url}" "${cert_sha}")"
  echo "installed=1 host_id=${host_id}"
  echo "ssh_host=${ssh_host}"
  echo "manager_config=${cfg_file}"
}

cmd_sync_config() {
  local host_id="" ssh_host=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --ssh-host) shift; ssh_host="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for sync-config." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  require_jq
  ssh_host="$(resolve_ssh_host "${host_id}" "${ssh_host}")"

  local output json_line api_url cert_sha cfg_file
  output="$(remote_exec "${ssh_host}" "set -e; (grep -Eo '\\{\"apiUrl\":\"[^\"]+\",\"certSha256\":\"[^\"]+\"\\}' /opt/outline/access.txt 2>/dev/null | head -n1) || true")"
  json_line="$(extract_manager_json "${output}")"
  [[ -n "${json_line}" ]] || {
    echo "Error: could not read manager JSON from /opt/outline/access.txt on host '${ssh_host}'." >&2
    exit 1
  }
  api_url="$(printf '%s' "${json_line}" | jq -r '.apiUrl')"
  cert_sha="$(printf '%s' "${json_line}" | jq -r '.certSha256')"
  cfg_file="$(save_manager_config "${host_id}" "${ssh_host}" "${api_url}" "${cert_sha}")"
  echo "synced=1 host_id=${host_id}"
  echo "ssh_host=${ssh_host}"
  echo "manager_config=${cfg_file}"
}

cmd_show_config() {
  local host_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for show-config." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"

  local file ssh_host api_url cert_sha
  IFS='|' read -r file ssh_host api_url cert_sha <<< "$(load_manager_config "${host_id}")"
  echo "host_id=${host_id}"
  echo "manager_config=${file}"
  echo "ssh_host=${ssh_host}"
  echo "api_url=${api_url}"
  echo "cert_sha256=${cert_sha}"
}

cmd_status() {
  local host_id="" ssh_host=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --ssh-host) shift; ssh_host="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for status." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  require_jq
  local file saved_ssh_host api_url cert_sha server_json
  IFS='|' read -r file saved_ssh_host api_url cert_sha <<< "$(load_manager_config "${host_id}")"
  if [[ -z "${ssh_host}" ]]; then
    ssh_host="${saved_ssh_host}"
  fi
  server_json="$(outline_api "${api_url}" GET "/server")"
  echo "host_id=${host_id}"
  echo "manager_config=${file}"
  echo "ssh_host=${ssh_host}"
  printf '%s' "${server_json}" | jq -r '"server_name=\(.name // "") port_for_new_keys=\(.portForNewAccessKeys // 0)"'
  if [[ -n "${ssh_host}" ]]; then
    echo "docker_status:"
    remote_exec "${ssh_host}" "docker ps --format 'name={{.Names}} status={{.Status}}'" || true
  else
    echo "note=no_ssh_host_saved_docker_status_skipped"
  fi
}

cmd_keys_list() {
  local host_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for keys-list." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  require_jq
  local api_url
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  outline_api "${api_url}" GET "/access-keys" \
    | jq -r '.accessKeys[] | "id=\(.id) name=\(.name // "") has_limit=\(.dataLimit != null)"'
}

cmd_keys_create() {
  local host_id="" count=1 prefix="outline" start_index=1 bytes="" print_urls=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --count) shift; count="${1:-}"; shift || true ;;
      --name-prefix) shift; prefix="${1:-}"; shift || true ;;
      --start-index) shift; start_index="${1:-}"; shift || true ;;
      --bytes) shift; bytes="${1:-}"; shift || true ;;
      --print-urls) print_urls=1; shift ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for keys-create." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  require_jq
  [[ "${count}" =~ ^[0-9]+$ ]] || { echo "Error: --count must be integer." >&2; exit 2; }
  [[ "${start_index}" =~ ^[0-9]+$ ]] || { echo "Error: --start-index must be integer." >&2; exit 2; }
  if [[ -n "${bytes}" && ! "${bytes}" =~ ^[0-9]+$ ]]; then
    echo "Error: --bytes must be integer." >&2
    exit 2
  fi
  local api_url
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  mkdir -p "${outline_dir}"
  chmod 700 "${outline_dir}" || true
  local out_file="${outline_dir}/${host_id}-keys-$(date -u +%Y-%m-%dT%H%M%SZ).txt"

  {
    echo "created_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "host_id=${host_id}"
    echo ""
  } > "${out_file}"

  local i created id access_url name idx
  for i in $(seq 1 "${count}"); do
    idx=$((start_index + i - 1))
    name="$(printf '%s-%02d' "${prefix}" "${idx}")"
    created="$(outline_api "${api_url}" POST "/access-keys")"
    id="$(printf '%s' "${created}" | jq -r '.id')"
    access_url="$(printf '%s' "${created}" | jq -r '.accessUrl')"
    outline_api "${api_url}" PUT "/access-keys/${id}/name" "{\"name\":\"${name}\"}" >/dev/null
    if [[ -n "${bytes}" ]]; then
      outline_api "${api_url}" PUT "/access-keys/${id}/data-limit" "{\"limit\":{\"bytes\":${bytes}}}" >/dev/null
    fi

    {
      echo "[${name}]"
      echo "id=${id}"
      echo "access_url=${access_url}"
      echo ""
    } >> "${out_file}"

    if [[ "${print_urls}" -eq 1 ]]; then
      echo "id=${id} name=${name} access_url=${access_url}"
    else
      echo "id=${id} name=${name}"
    fi
  done
  chmod 600 "${out_file}" || true
  echo "keys_file=${out_file}"
}

cmd_key_delete() {
  local host_id="" key_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --id) shift; key_id="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for key-delete." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  [[ -n "${key_id}" ]] || { echo "Error: --id is required." >&2; exit 2; }
  local api_url
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  outline_api "${api_url}" DELETE "/access-keys/${key_id}" >/dev/null
  echo "deleted_key_id=${key_id}"
}

cmd_keys_delete() {
  local host_id="" ids_csv=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --ids) shift; ids_csv="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for keys-delete." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  [[ -n "${ids_csv}" ]] || { echo "Error: --ids is required." >&2; exit 2; }
  local api_url
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  local id
  IFS=',' read -r -a ids <<< "${ids_csv}"
  for id in "${ids[@]}"; do
    [[ -n "${id}" ]] || continue
    outline_api "${api_url}" DELETE "/access-keys/${id}" >/dev/null
    echo "deleted_key_id=${id}"
  done
}

cmd_keys_delete_all() {
  local host_id="" keep_ids_csv="" confirm="no"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --keep-ids) shift; keep_ids_csv="${1:-}"; shift || true ;;
      --yes) confirm="yes"; shift ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for keys-delete-all." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  [[ "${confirm}" == "yes" ]] || {
    echo "Error: keys-delete-all requires --yes." >&2
    exit 2
  }
  require_jq
  local api_url all_json deleted=0
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  all_json="$(outline_api "${api_url}" GET "/access-keys")"
  local keep_set=",${keep_ids_csv},"
  local id
  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    if [[ "${keep_set}" == *",${id},"* ]]; then
      continue
    fi
    outline_api "${api_url}" DELETE "/access-keys/${id}" >/dev/null
    echo "deleted_key_id=${id}"
    deleted=$((deleted + 1))
  done < <(printf '%s' "${all_json}" | jq -r '.accessKeys[].id')
  echo "deleted_total=${deleted}"
}

cmd_key_limit() {
  local host_id="" key_id="" bytes=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --id) shift; key_id="${1:-}"; shift || true ;;
      --bytes) shift; bytes="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for key-limit." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  [[ -n "${key_id}" ]] || { echo "Error: --id is required." >&2; exit 2; }
  [[ "${bytes}" =~ ^[0-9]+$ ]] || { echo "Error: --bytes must be integer." >&2; exit 2; }
  local api_url
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  outline_api "${api_url}" PUT "/access-keys/${key_id}/data-limit" "{\"limit\":{\"bytes\":${bytes}}}" >/dev/null
  echo "limited_key_id=${key_id} bytes=${bytes}"
}

cmd_key_unlimit() {
  local host_id="" key_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host-id) shift; host_id="${1:-}"; shift || true ;;
      --id) shift; key_id="${1:-}"; shift || true ;;
      -h|--help|help) usage; exit 0 ;;
      *) echo "Error: unknown option '$1' for key-unlimit." >&2; exit 2 ;;
    esac
  done
  require_host_id "${host_id}"
  [[ -n "${key_id}" ]] || { echo "Error: --id is required." >&2; exit 2; }
  local api_url
  IFS='|' read -r _ _ api_url _ <<< "$(load_manager_config "${host_id}")"
  outline_api "${api_url}" DELETE "/access-keys/${key_id}/data-limit" >/dev/null
  echo "unlimited_key_id=${key_id}"
}

main() {
  require_cmd bash
  require_cmd curl
  require_cmd ssh

  [[ $# -gt 0 ]] || {
    usage
    exit 2
  }

  local cmd="$1"
  shift
  case "${cmd}" in
    install) cmd_install "$@" ;;
    sync-config) cmd_sync_config "$@" ;;
    show-config) cmd_show_config "$@" ;;
    status) cmd_status "$@" ;;
    keys-list) cmd_keys_list "$@" ;;
    keys-create) cmd_keys_create "$@" ;;
    key-delete) cmd_key_delete "$@" ;;
    keys-delete) cmd_keys_delete "$@" ;;
    keys-delete-all) cmd_keys_delete_all "$@" ;;
    key-limit) cmd_key_limit "$@" ;;
    key-unlimit) cmd_key_unlimit "$@" ;;
    -h|--help|help)
      usage
      ;;
    *)
      echo "Error: unknown command '${cmd}'." >&2
      usage
      exit 2
      ;;
  esac
}

main "$@"
