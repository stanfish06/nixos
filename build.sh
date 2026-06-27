#!/usr/bin/env bash
set -euo pipefail

backup="${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix"

nix flake update

if [ -f "$backup" ]; then
  cp "$backup" local-hosts.nix
fi

case "$1" in
  beelink-1)
    NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake .#nixos_linux_beelink_1
    ;;
  gmktec-1)
    NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake .#nixos_linux_gmktec_1
    ;;
  *)
    echo "machine not recognized"
    ;;
esac
