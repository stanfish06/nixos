#!/usr/bin/env bash
set -euo pipefail

backup="${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix"

# Complete the read-only conflict preflight before treefmt or filesystem writes.
index_changed=false
if git diff --cached --quiet --no-ext-diff --no-textconv HEAD -- local-hosts.nix; then
  :
else
  diff_status=$?
  if ((diff_status == 1)); then
    index_changed=true
  else
    printf 'error: cannot safely compare staged local-hosts.nix with HEAD\n' >&2
    exit "$diff_status"
  fi
fi

working_changed_from_head=false
if git diff --quiet --no-ext-diff --no-textconv HEAD -- local-hosts.nix; then
  :
else
  diff_status=$?
  if ((diff_status == 1)); then
    working_changed_from_head=true
  else
    printf 'error: cannot safely compare working local-hosts.nix with HEAD\n' >&2
    exit "$diff_status"
  fi
fi

working_changed_from_index=false
if git diff --quiet --no-ext-diff --no-textconv -- local-hosts.nix; then
  :
else
  diff_status=$?
  if ((diff_status == 1)); then
    working_changed_from_index=true
  else
    printf 'error: cannot safely compare working and staged local-hosts.nix\n' >&2
    exit "$diff_status"
  fi
fi

if [[ "$index_changed" == true && "$working_changed_from_head" == true && "$working_changed_from_index" == true ]]; then
  printf 'error: staged and working local-hosts.nix mappings conflict; reconcile them before retrying\n' >&2
  exit 1
fi

treefmt
mkdir -p "$(dirname "$backup")"

if [[ "$working_changed_from_head" == true ]]; then
  cp -- local-hosts.nix "$backup"
  printf 'Saved private local-hosts.nix to %s.\n' "$backup"
elif [[ "$index_changed" == true ]]; then
  temp_backup="$(mktemp "${backup}.tmp.XXXXXX")"
  trap 'rm -f -- "$temp_backup"' EXIT
  git show :local-hosts.nix >"$temp_backup"
  mv -- "$temp_backup" "$backup"
  trap - EXIT
  printf 'Saved staged private local-hosts.nix to %s.\n' "$backup"
elif [[ -f "$backup" ]]; then
  printf 'local-hosts.nix matches HEAD; retained the existing private backup.\n'
else
  printf 'local-hosts.nix matches HEAD; no private changes exist to save.\n'
fi

git restore --source=HEAD --staged --worktree -- local-hosts.nix
