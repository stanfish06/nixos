#!/usr/bin/env bash
set -euo pipefail

backup="${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix"
mkdir -p "$(dirname "$backup")"

treefmt
cp local-hosts.nix "$backup"
git restore --source=HEAD -- local-hosts.nix
