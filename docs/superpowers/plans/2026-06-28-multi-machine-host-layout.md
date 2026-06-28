# Multi-machine Host Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Beelink and GMKtec clean host modules, correct storage settings, distinct hostnames, and a safe build script that can build many configurations but switch only the current machine.

**Architecture:** A shared `mkLinuxSystem` constructor in `flake.nix` owns the common Linux and Home Manager modules. Each directory under `hosts/` is a concrete host adapter that sets one hostname and imports one generated hardware module. `build.sh` discovers those host directories, maps the running hostname to a short selector, and keeps non-activating multi-host builds separate from single-host activation.

**Tech Stack:** Nix flakes, NixOS modules, Bash, `nixos-rebuild`, `nix build`, treefmt

---

## File map

- Create `hosts/beelink-1/default.nix`: Beelink hostname and hardware imports.
- Move `hardware-configuration-beelink-1.nix` to
  `hosts/beelink-1/hardware-configuration.nix`: Beelink storage and hardware.
- Create `hosts/gmktec-1/default.nix`: GMKtec hostname and hardware imports.
- Move `hardware-configuration-gmktec-1.nix` to
  `hosts/gmktec-1/hardware-configuration.nix`: GMKtec storage and hardware.
- Modify `configuration-linux.nix`: remove the shared hostname.
- Modify `flake.nix`: add the shared Linux constructor and new flake names.
- Modify `build.sh`: implement discovery, routing, safety checks, and explicit
  updates.
- Create `tests/flake.sh`: verify hostnames, layout, and swap-device evaluation.
- Create `tests/build.sh`: regression-test build and switch routing with fake
  commands.
- Modify `README.md`: document the two hosts and command interface.

### Task 1: Create host modules and deduplicate the flake

**Files:**

- Create: `tests/flake.sh`
- Create: `hosts/beelink-1/default.nix`
- Create: `hosts/gmktec-1/default.nix`
- Move: `hardware-configuration-beelink-1.nix` →
  `hosts/beelink-1/hardware-configuration.nix`
- Move: `hardware-configuration-gmktec-1.nix` →
  `hosts/gmktec-1/hardware-configuration.nix`
- Modify: `hosts/gmktec-1/hardware-configuration.nix`
- Modify: `configuration-linux.nix:118`
- Modify: `flake.nix:35-116`

- [ ] **Step 1: Add the failing host-evaluation test**

Create `tests/flake.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_equal() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\nexpected: %q\nactual:   %q\n' \
      "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_equal \
  "nixos-beelink-1" \
  "$(nix eval --raw --no-write-lock-file \
    .#nixosConfigurations.nixos-beelink-1.config.networking.hostName)" \
  "Beelink hostname"

assert_equal \
  "nixos-gmktec-1" \
  "$(nix eval --raw --no-write-lock-file \
    .#nixosConfigurations.nixos-gmktec-1.config.networking.hostName)" \
  "GMKtec hostname"

beelink_swaps="$(
  nix eval --raw --no-write-lock-file \
    .#nixosConfigurations.nixos-beelink-1.config.swapDevices \
    --apply 'devices: builtins.concatStringsSep "\n" (map (entry: entry.device) devices)'
)"
assert_equal \
  $'/dev/disk/by-uuid/1f38fb1d-bb77-4276-afe2-82f81ec25af5\n/var/lib/swapfile' \
  "$beelink_swaps" \
  "Beelink swap devices"

gmktec_swaps="$(
  nix eval --raw --no-write-lock-file \
    .#nixosConfigurations.nixos-gmktec-1.config.swapDevices \
    --apply 'devices: builtins.concatStringsSep "\n" (map (entry: entry.device) devices)'
)"
assert_equal \
  "/var/lib/swapfile" \
  "$gmktec_swaps" \
  "GMKtec swap devices"

[[ -f hosts/beelink-1/default.nix ]] ||
  fail "hosts/beelink-1/default.nix is missing"
[[ -f hosts/beelink-1/hardware-configuration.nix ]] ||
  fail "Beelink hardware module is missing"
[[ -f hosts/gmktec-1/default.nix ]] ||
  fail "hosts/gmktec-1/default.nix is missing"
[[ -f hosts/gmktec-1/hardware-configuration.nix ]] ||
  fail "GMKtec hardware module is missing"
[[ ! -e hardware-configuration-beelink-1.nix ]] ||
  fail "legacy Beelink hardware path still exists"
[[ ! -e hardware-configuration-gmktec-1.nix ]] ||
  fail "legacy GMKtec hardware path still exists"

printf 'flake host tests passed\n'
```

- [ ] **Step 2: Run the test and confirm the new flake names fail**

Run:

```bash
bash tests/flake.sh
```

Expected: nonzero status because
`nixosConfigurations.nixos-beelink-1` does not exist yet.

- [ ] **Step 3: Move each generated hardware module beside its host**

Run:

```bash
mkdir -p hosts/beelink-1 hosts/gmktec-1
git mv hardware-configuration-beelink-1.nix \
  hosts/beelink-1/hardware-configuration.nix
git mv hardware-configuration-gmktec-1.nix \
  hosts/gmktec-1/hardware-configuration.nix
```

- [ ] **Step 4: Add the two host entry modules**

Create `hosts/beelink-1/default.nix`:

```nix
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-beelink-1";
}
```

Create `hosts/gmktec-1/default.nix`:

```nix
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-gmktec-1";
}
```

- [ ] **Step 5: Remove the false GMKtec swap-partition declaration**

In `hosts/gmktec-1/hardware-configuration.nix`, replace:

```nix
  swapDevices = [
    { device = "/dev/disk/by-uuid/876704ad-b811-4baf-980b-88bc6c521643"; }
    {
      device = "/var/lib/swapfile";
      size = 48 * 1024; # MiB
    }
  ];
```

with:

```nix
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 48 * 1024; # MiB
    }
  ];
```

- [ ] **Step 6: Remove the hostname from the shared Linux module**

Delete this line from `configuration-linux.nix`:

```nix
  networking.hostName = "nixos"; # Define your hostname.
```

- [ ] **Step 7: Replace duplicated Linux flake definitions with one constructor**

Replace the complete `outputs` value in `flake.nix` with:

```nix
  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";

      mkLinuxSystem =
        hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    system = prev.stdenv.hostPlatform.system;
                    config.allowUnfree = true;
                    overlays = [ inputs.neovim-nightly.overlays.default ];
                  };
                  new = import inputs.nixpkgs-new {
                    system = prev.stdenv.hostPlatform.system;
                    config.allowUnfree = true;
                  };
                })
                inputs.dolphin-overlay.overlays.default
              ];
            }
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.stan = {
                imports = [
                  ./home.nix
                  inputs.codex-desktop.homeManagerModules.codex-desktop-linux
                ];
              };
            }
            ./configuration-linux.nix
            ./local-hosts.nix
            hostModule
          ];
        };
    in
    {
      nixosConfigurations = {
        nixos_wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            inputs.nixos-wsl.nixosModules.wsl
            {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
                })
              ];
            }
            ./configuration-wsl.nix
          ];
        };

        nixos-beelink-1 = mkLinuxSystem ./hosts/beelink-1/default.nix;
        nixos-gmktec-1 = mkLinuxSystem ./hosts/gmktec-1/default.nix;
      };
    };
```

- [ ] **Step 8: Format and run the host-evaluation test**

Run:

```bash
treefmt
bash tests/flake.sh
```

Expected:

```text
flake host tests passed
```

- [ ] **Step 9: Commit the host layout**

Run:

```bash
git add flake.nix configuration-linux.nix hosts tests/flake.sh
git commit -m "refactor: organize physical host configurations"
```

### Task 2: Implement safe build and switch routing

**Files:**

- Create: `tests/build.sh`
- Modify: `build.sh`

- [ ] **Step 1: Add routing regression tests with fake system commands**

Create `tests/build.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_dir="$tmp_dir/repo"
fake_bin="$tmp_dir/bin"
state_dir="$tmp_dir/state"
call_log="$tmp_dir/calls.log"

mkdir -p "$fixture_dir" "$fake_bin" "$state_dir/nixos"
cp "$repo_dir/build.sh" "$repo_dir/local-hosts.nix" "$fixture_dir/"
cp -R "$repo_dir/hosts" "$fixture_dir/"

cat >"$state_dir/nixos/local-hosts.nix" <<'EOF'
{
  networking.hosts = {
    "127.0.0.2" = [ "fixture-host" ];
  };
}
EOF

cat >"$fake_bin/hostname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${FAKE_HOSTNAME:?}"
EOF

cat >"$fake_bin/nix" <<'EOF'
#!/usr/bin/env bash
printf 'nix' >>"$CALL_LOG"
printf '|%s' "$@" >>"$CALL_LOG"
printf '\n' >>"$CALL_LOG"
EOF

cat >"$fake_bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo' >>"$CALL_LOG"
printf '|%s' "$@" >>"$CALL_LOG"
printf '\n' >>"$CALL_LOG"
"$@"
EOF

cat >"$fake_bin/nixos-rebuild" <<'EOF'
#!/usr/bin/env bash
printf 'nixos-rebuild' >>"$CALL_LOG"
printf '|%s' "$@" >>"$CALL_LOG"
printf '\n' >>"$CALL_LOG"
EOF

chmod +x "$fake_bin"/*

status=0
output=""

run_build() {
  local fake_hostname="$1"
  shift
  : >"$call_log"

  set +e
  output="$(
    cd "$tmp_dir"
    PATH="$fake_bin:$PATH" \
      CALL_LOG="$call_log" \
      XDG_STATE_HOME="$state_dir" \
      FAKE_HOSTNAME="$fake_hostname" \
      "$fixture_dir/build.sh" "$@" 2>&1
  )"
  status=$?
  set -e
}

assert_status() {
  local expected="$1"
  if [[ "$status" -ne "$expected" ]]; then
    printf 'FAIL: expected status %s, got %s\n%s\n' \
      "$expected" "$status" "$output" >&2
    exit 1
  fi
}

assert_output_contains() {
  local expected="$1"
  if [[ "$output" != *"$expected"* ]]; then
    printf 'FAIL: output does not contain %q\n%s\n' \
      "$expected" "$output" >&2
    exit 1
  fi
}

assert_log_line() {
  local expected="$1"
  if ! grep -Fqx -- "$expected" "$call_log"; then
    printf 'FAIL: call log does not contain %q\n' "$expected" >&2
    sed -n '1,80p' "$call_log" >&2
    exit 1
  fi
}

run_build nixos-beelink-1 switch
assert_status 0
assert_log_line \
  'sudo|nixos-rebuild|switch|--no-write-lock-file|--flake|.#nixos-beelink-1'

run_build nixos switch gmktec-1
assert_status 0
assert_log_line \
  'sudo|nixos-rebuild|switch|--no-write-lock-file|--flake|.#nixos-gmktec-1'

run_build nixos-beelink-1 switch gmktec-1
assert_status 2
assert_output_contains "refusing to switch"

run_build nixos-beelink-1 switch all
assert_status 2
assert_output_contains "exactly one host"

run_build nixos-beelink-1 build
assert_status 0
assert_log_line \
  'nix|build|--no-link|--no-write-lock-file|.#nixosConfigurations.nixos-beelink-1.config.system.build.toplevel'

run_build nixos-beelink-1 build gmktec-1 beelink-1
assert_status 0
assert_log_line \
  'nix|build|--no-link|--no-write-lock-file|.#nixosConfigurations.nixos-gmktec-1.config.system.build.toplevel|.#nixosConfigurations.nixos-beelink-1.config.system.build.toplevel'

run_build nixos-beelink-1 build all
assert_status 0
assert_log_line \
  'nix|build|--no-link|--no-write-lock-file|.#nixosConfigurations.nixos-beelink-1.config.system.build.toplevel|.#nixosConfigurations.nixos-gmktec-1.config.system.build.toplevel'

run_build nixos-beelink-1 build unknown-host
assert_status 2
assert_output_contains "unknown host"

run_build legacy-host build
assert_status 2
assert_output_contains "cannot auto-detect"

run_build nixos-beelink-1 update
assert_status 0
assert_log_line 'nix|flake|update'

cmp \
  "$state_dir/nixos/local-hosts.nix" \
  "$fixture_dir/local-hosts.nix"

printf 'build routing tests passed\n'
```

- [ ] **Step 2: Run the test and verify the old interface fails**

Run:

```bash
bash tests/build.sh
```

Expected: nonzero status because the current script does not recognize the
`switch` action or emit the expected command.

- [ ] **Step 3: Replace `build.sh` with the routing module**

Replace `build.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

usage() {
  cat <<'EOF'
Usage:
  ./build.sh switch
  ./build.sh switch <host>
  ./build.sh build
  ./build.sh build <host>...
  ./build.sh build all
  ./build.sh update

Hosts are discovered from hosts/*/default.nix.
Multi-host builds are safe and do not activate configurations.
Switch accepts exactly one host and activates it on the current machine.
EOF
}

fail() {
  printf 'error: %s\n\n' "$*" >&2
  usage >&2
  exit 2
}

list_hosts() {
  local config

  for config in "$repo_dir"/hosts/*/default.nix; do
    [[ -f "$config" ]] || continue
    basename "$(dirname "$config")"
  done
}

is_host() {
  local candidate="$1"
  local known

  while IFS= read -r known; do
    [[ "$known" == "$candidate" ]] && return 0
  done < <(list_hosts)

  return 1
}

validate_host() {
  local host="$1"
  is_host "$host" || fail "unknown host '$host'"
}

managed_host_from_name() {
  local hostname="$1"
  local host

  [[ "$hostname" == nixos-* ]] || return 1
  host="${hostname#nixos-}"
  is_host "$host" || return 1
  printf '%s\n' "$host"
}

detect_host() {
  local hostname
  local host

  hostname="$(hostname -s)"
  if ! host="$(managed_host_from_name "$hostname")"; then
    fail "cannot auto-detect a managed host from hostname '$hostname'; specify a host"
  fi

  printf '%s\n' "$host"
}

restore_local_hosts() {
  local backup
  backup="${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix"

  if [[ -f "$backup" ]]; then
    cp -- "$backup" "$repo_dir/local-hosts.nix"
  fi
}

switch_host() {
  local host
  local running_host

  (($# <= 1)) || fail "switch accepts exactly one host"

  if (($# == 0)); then
    host="$(detect_host)"
  else
    host="$1"
    [[ "$host" != "all" ]] || fail "switch accepts exactly one host, not 'all'"
    validate_host "$host"

    running_host="$(managed_host_from_name "$(hostname -s)" || true)"
    if [[ -n "$running_host" && "$running_host" != "$host" ]]; then
      fail "refusing to switch '$running_host' using the '$host' configuration"
    fi
  fi

  restore_local_hosts
  sudo nixos-rebuild switch --no-write-lock-file --flake ".#nixos-$host"
}

build_hosts() {
  local requested
  local host
  local -a hosts=()
  local -a installables=()
  local -A seen=()

  if (($# == 0)); then
    hosts=("$(detect_host)")
  elif (($# == 1)) && [[ "$1" == "all" ]]; then
    mapfile -t hosts < <(list_hosts)
  else
    for requested in "$@"; do
      [[ "$requested" != "all" ]] ||
        fail "'all' must be the only build selector"
      validate_host "$requested"

      if [[ -z "${seen[$requested]+present}" ]]; then
        hosts+=("$requested")
        seen["$requested"]=1
      fi
    done
  fi

  ((${#hosts[@]} > 0)) || fail "no hosts found under '$repo_dir/hosts'"

  for host in "${hosts[@]}"; do
    installables+=(
      ".#nixosConfigurations.nixos-$host.config.system.build.toplevel"
    )
  done

  restore_local_hosts
  nix build --no-link --no-write-lock-file "${installables[@]}"
}

main() {
  local action

  (($# > 0)) || fail "missing action"
  action="$1"
  shift

  case "$action" in
    switch)
      switch_host "$@"
      ;;
    build)
      build_hosts "$@"
      ;;
    update)
      (($# == 0)) || fail "update does not accept host selectors"
      nix flake update
      ;;
    help | -h | --help)
      (($# == 0)) || fail "help does not accept arguments"
      usage
      ;;
    *)
      fail "unknown action '$action'"
      ;;
  esac
}

main "$@"
```

- [ ] **Step 4: Run syntax and routing tests**

Run:

```bash
bash -n build.sh tests/build.sh
bash tests/build.sh
```

Expected:

```text
build routing tests passed
```

- [ ] **Step 5: Commit the routing implementation**

Run:

```bash
git add build.sh tests/build.sh
git commit -m "feat: add safe multi-host build routing"
```

### Task 3: Document the multi-machine workflow

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Replace the README with the complete operator workflow**

Replace `README.md` with:

````markdown
# NixOS configuration

This flake manages two physical `x86_64-linux` machines and one WSL
configuration.

| Host selector | Configured hostname | Host module |
| --- | --- | --- |
| `beelink-1` | `nixos-beelink-1` | `hosts/beelink-1/` |
| `gmktec-1` | `nixos-gmktec-1` | `hosts/gmktec-1/` |

Shared Linux configuration remains in `configuration-linux.nix` and `home.nix`.
Both physical hosts also import the root `local-hosts.nix`.

## Switch the current machine

After the configured hostname is active, detect it automatically:

```bash
./build.sh switch
```

During initial bootstrap from an unmanaged hostname such as `nixos`, select one
host explicitly:

```bash
./build.sh switch beelink-1
./build.sh switch gmktec-1
```

`switch` accepts only one host. If the running machine already has a managed
hostname, the script refuses to switch it using the other machine's
configuration.

## Build without activating

Build the current detected host:

```bash
./build.sh build
```

Build one host, a selected set, or every physical host:

```bash
./build.sh build beelink-1
./build.sh build beelink-1 gmktec-1
./build.sh build all
```

These commands only build NixOS system closures in the local Nix store. They do
not activate another machine's storage, boot, or service configuration.

## Update flake inputs

Dependency updates are explicit:

```bash
./build.sh update
```

Ordinary builds and switches do not modify `flake.lock`.

## Local host mappings

The committed `local-hosts.nix` is an empty dummy module. Before a physical-host
build or switch, `build.sh` restores the private copy from:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix
```

Before committing, format the repository, save the current private mappings,
and restore the committed dummy:

```bash
./run-before-commit.sh
git add .
git commit -m "..."
git push
```
````

- [ ] **Step 2: Format and inspect the rendered Markdown source**

Run:

```bash
treefmt
sed -n '1,240p' README.md
```

Expected: the host table, switch commands, build commands, update command, and
local-hosts workflow are all present.

- [ ] **Step 3: Commit the documentation**

Run:

```bash
git add README.md
git commit -m "docs: explain multi-machine build workflow"
```

### Task 4: Verify both complete host configurations

**Files:**

- Verify: `build.sh`
- Verify: `tests/build.sh`
- Verify: `tests/flake.sh`
- Verify: `flake.nix`
- Verify: `hosts/beelink-1/default.nix`
- Verify: `hosts/gmktec-1/default.nix`

- [ ] **Step 1: Run all fast regression checks**

Run:

```bash
bash -n build.sh tests/build.sh tests/flake.sh
bash tests/build.sh
bash tests/flake.sh
```

Expected:

```text
build routing tests passed
flake host tests passed
```

- [ ] **Step 2: Verify formatting and whitespace**

Run:

```bash
treefmt --ci
git diff --check
```

Expected: both commands exit successfully with no changed files or whitespace
errors.

- [ ] **Step 3: Evaluate the complete flake without changing its lock**

Run:

```bash
nix flake check --no-build --no-write-lock-file
```

Expected output includes:

```text
checking NixOS configuration 'nixosConfigurations.nixos-beelink-1'...
checking NixOS configuration 'nixosConfigurations.nixos-gmktec-1'...
all checks passed!
```

- [ ] **Step 4: Build both physical system closures without activation**

Run:

```bash
tmp_state="$(mktemp -d)"
trap 'rm -rf "$tmp_state"' EXIT
XDG_STATE_HOME="$tmp_state" ./build.sh build all
```

Expected: exit status 0. Neither system is activated and no `result` symlink is
created because the script uses `nix build --no-link`.

- [ ] **Step 5: Confirm sensitive and generated files did not drift**

Run:

```bash
git diff --exit-code -- flake.lock local-hosts.nix
git status --short --branch
```

Expected: no diff for `flake.lock` or `local-hosts.nix`; the branch status shows
only the intentional implementation commits and no uncommitted files.
