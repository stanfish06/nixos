#!/usr/bin/env bash
set -euo pipefail

backup="${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix"

nix flake update

if [ -f "$backup" ]; then
  cp "$backup" local-hosts.nix
fi

NIXPKGS_ALLOW_UNFREE=1 sudo nixos-rebuild switch --flake .#nixos_linux
