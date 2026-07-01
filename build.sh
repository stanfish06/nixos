#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

declare -a hosts=()

usage() {
  cat <<EOF
Usage:
  ./build.sh switch
  ./build.sh switch <host>
  ./build.sh build
  ./build.sh build <host>...
  ./build.sh build all
  ./build.sh update
  ./build.sh help

Valid hosts: ${hosts[*]:-(none)}
EOF
}

usage_error() {
  printf 'error: %s\n\n' "$1" >&2
  usage >&2
  exit 2
}

for host_config in hosts/*/default.nix; do
  if [[ -f "$host_config" ]]; then
    host="$(basename -- "$(dirname -- "$host_config")")"
    if [[ ! "$host" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
      usage_error "invalid host directory '$host'; expected [a-z0-9][a-z0-9-]*"
    fi
    if [[ "$host" == "all" ]]; then
      usage_error "host directory 'all' uses a reserved selector"
    fi
    hosts+=("$host")
  fi
done

is_valid_host() {
  local candidate="$1"
  local host

  for host in "${hosts[@]}"; do
    if [[ "$candidate" == "$host" ]]; then
      return 0
    fi
  done

  return 1
}

managed_host_for_hostname() {
  local system_hostname="$1"
  local candidate

  if [[ "$system_hostname" != nixos-* ]]; then
    return 1
  fi

  candidate="${system_hostname#nixos-}"
  if ! is_valid_host "$candidate"; then
    return 1
  fi

  printf '%s\n' "$candidate"
}

detect_managed_host() {
  local system_hostname

  system_hostname="$(hostname -s)"
  if ! managed_host_for_hostname "$system_hostname"; then
    usage_error "cannot auto-detect a managed host from hostname '$system_hostname'; specify a host"
  fi
}

sync_local_hosts() {
  local backup="${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix"
  local compare_status
  local diff_status

  if [[ -f "$backup" ]]; then
    if git diff --quiet --no-ext-diff --no-textconv HEAD -- local-hosts.nix; then
      :
    else
      diff_status=$?
      if (( diff_status > 1 )); then
        usage_error "cannot safely compare local-hosts.nix with HEAD"
      fi

      if cmp --silent -- local-hosts.nix "$backup"; then
        :
      else
        compare_status=$?
        if (( compare_status > 1 )); then
          usage_error "cannot safely compare local-hosts.nix with its private backup"
        fi
        usage_error "local-hosts.nix has unsaved changes that differ from its private backup; save the new mappings with ./run-before-commit.sh before building or switching"
      fi
    fi

    cp -- "$backup" local-hosts.nix
  fi
}

switch_host() {
  local system_hostname
  local current_host=""
  local target_host

  if (( $# > 1 )); then
    usage_error "switch accepts exactly one host"
  fi

  system_hostname="$(hostname -s)"
  if current_host="$(managed_host_for_hostname "$system_hostname")"; then
    :
  elif [[ "$system_hostname" == nixos-* ]]; then
    usage_error "hostname '$system_hostname' is in the managed 'nixos-' namespace but has no discovered host"
  fi

  if (( $# == 0 )); then
    if [[ -z "$current_host" ]]; then
      usage_error "cannot auto-detect a managed host from hostname '$system_hostname'; specify a host"
    fi
    target_host="$current_host"
  else
    target_host="$1"
    if [[ "$target_host" == "all" ]]; then
      usage_error "switch accepts exactly one host, not 'all'"
    fi
    if ! is_valid_host "$target_host"; then
      usage_error "unknown host '$target_host'"
    fi
    if [[ -n "$current_host" && "$target_host" != "$current_host" ]]; then
      usage_error "refusing to switch '$target_host' from managed host '$current_host'"
    fi
  fi

  sync_local_hosts
  # sudo nixos-rebuild switch --no-write-lock-file --flake ".#nixos-$target_host" --offline (in case network issue and need rebuild)
  sudo nixos-rebuild switch --no-write-lock-file --flake ".#nixos-$target_host"
}

build_hosts() {
  local -a selected_hosts=()
  local -a installables=()
  local host
  local selected
  local duplicate

  if (( $# == 0 )); then
    selected_hosts+=("$(detect_managed_host)")
  elif [[ "$1" == "all" ]]; then
    if (( $# != 1 )); then
      usage_error "'all' must be the only build selector"
    fi
    selected_hosts=("${hosts[@]}")
  else
    for host in "$@"; do
      if [[ "$host" == "all" ]]; then
        usage_error "'all' must be the only build selector"
      fi
      if ! is_valid_host "$host"; then
        usage_error "unknown host '$host'"
      fi

      duplicate=false
      for selected in "${selected_hosts[@]}"; do
        if [[ "$host" == "$selected" ]]; then
          duplicate=true
          break
        fi
      done
      if [[ "$duplicate" == false ]]; then
        selected_hosts+=("$host")
      fi
    done
  fi

  if (( ${#selected_hosts[@]} == 0 )); then
    usage_error "no managed hosts were discovered under hosts/"
  fi

  for host in "${selected_hosts[@]}"; do
    installables+=(".#nixosConfigurations.nixos-$host.config.system.build.toplevel")
  done

  sync_local_hosts
  nix build --no-link --no-write-lock-file "${installables[@]}"
}

action="${1:-}"
if (( $# > 0 )); then
  shift
fi

case "$action" in
  switch)
    switch_host "$@"
    ;;
  build)
    build_hosts "$@"
    ;;
  update)
    if (( $# != 0 )); then
      usage_error "update does not accept host selectors"
    fi
    nix flake update
    ;;
  help | -h | --help)
    if (( $# != 0 )); then
      usage_error "help does not accept arguments"
    fi
    usage
    ;;
  *)
    if [[ -z "$action" ]]; then
      usage_error "missing action"
    fi
    usage_error "unknown action '$action'"
    ;;
esac
