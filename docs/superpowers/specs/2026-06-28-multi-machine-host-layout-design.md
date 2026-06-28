# Multi-machine host layout and build routing

Status: approved

## Context

The `multi-machine` branch adds a GMKtec NixOS configuration alongside the
existing Beelink configuration. Both configurations evaluate successfully, but
the current structure duplicates most of the Linux flake definition and leaves
host selection entirely to a fragile positional argument in `build.sh`.

The repository review found the following host-related issues:

- The GMKtec configuration declares its ext4 root UUID as a swap device. It has
  no dedicated swap partition and should use only its swapfile.
- Both Linux configurations currently set `networking.hostName = "nixos"`, so
  the running host cannot be identified reliably.
- `build.sh` updates `flake.lock` on every invocation, reads an unset positional
  argument under `set -u`, and returns success for unknown machine names.
- The Beelink and GMKtec flake definitions duplicate their overlays, Home
  Manager setup, and shared Linux module list.
- `local-hosts.nix` is intentionally committed as a dummy module and replaced
  from a local state backup before use. Both Linux hosts need this shared local
  module.

The live Beelink storage layout matches its hardware configuration: it has a
dedicated swap partition in addition to the managed swapfile. That partition
will remain configured.

## Goals

- Give each physical machine an explicit hostname and self-contained host
  directory.
- Keep shared Linux and Home Manager configuration shared.
- Make local builds of one, several, or all physical hosts straightforward.
- Make switching safe by limiting it to one physical host at a time.
- Auto-detect the current physical host after the new hostnames are active.
- Preserve an explicit host selector for initial bootstrap.
- Keep dependency updates deliberate and separate from ordinary builds.
- Preserve the existing dummy-and-local-override workflow for
  `local-hosts.nix`, applying it to both physical hosts.

## Non-goals

- Remote deployment or switching multiple physical machines over SSH.
- Reorganizing the WSL configuration.
- Repartitioning either machine.
- Changing unrelated user, package, desktop, or password configuration.
- Replacing the existing local-hosts backup workflow with a secrets manager.

## Repository layout

Machine-specific modules move under `hosts/`:

```text
hosts/
  beelink-1/
    default.nix
    hardware-configuration.nix
  gmktec-1/
    default.nix
    hardware-configuration.nix
```

Each `default.nix` imports its adjacent generated hardware module and sets the
machine hostname:

- `beelink-1` sets `networking.hostName = "nixos-beelink-1"`.
- `gmktec-1` sets `networking.hostName = "nixos-gmktec-1"`.

Shared files such as `configuration-linux.nix`, `home.nix`, and
`local-hosts.nix` remain at the repository root. This keeps the refactor focused
on the host seam without introducing a broader `modules/` hierarchy.

## Flake design

`flake.nix` will define one internal Linux-system constructor containing the
shared overlays, Home Manager integration, `configuration-linux.nix`, and
`local-hosts.nix`.

The two `nixosConfigurations` entries will call that constructor with their
host module:

- `nixos-beelink-1` uses `hosts/beelink-1/default.nix`.
- `nixos-gmktec-1` uses `hosts/gmktec-1/default.nix`.

The WSL configuration remains separate and unchanged.

Both physical hosts import the same root `local-hosts.nix`. Before a build or
switch, `build.sh` restores the private copy from
`${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix` when that backup
exists. The committed file remains the empty dummy configuration, and
`run-before-commit.sh` continues to restore that dummy before commits.

## Storage correction

The GMKtec hardware module will remove this invalid entry:

```nix
{ device = "/dev/disk/by-uuid/876704ad-b811-4baf-980b-88bc6c521643"; }
```

That UUID belongs to its ext4 root filesystem, not swap. GMKtec will retain only
the managed 48 GiB swapfile.

The Beelink hardware module will retain both its actual swap partition and its
48 GiB swapfile.

## Build script interface

`build.sh` will expose three actions:

```text
./build.sh switch
./build.sh switch <host>
./build.sh build
./build.sh build <host>...
./build.sh build all
./build.sh update
```

Host selectors use the short directory names `beelink-1` and `gmktec-1`.
Multiple selectors are separated by spaces. A literal `|` is not supported
because an unquoted pipe is shell syntax rather than an argument separator.

### `switch`

- With no host argument, read the short hostname and map
  `nixos-beelink-1`/`nixos-gmktec-1` to the corresponding host.
- With one explicit host, use it for initial bootstrap while the current
  hostname is still unmanaged, such as the legacy `nixos`.
- If the running hostname already identifies one managed host, reject an
  explicit request to switch to the other host.
- Reject `all` and multiple hosts because a local switch activates storage,
  boot, and service configuration on the current machine.
- Run `sudo nixos-rebuild switch --flake ".#nixos-<host>"`.

### `build`

- With no host argument, auto-detect the current managed host.
- With explicit host arguments, build exactly that selected set.
- Expand `all` to every directory under `hosts/`.
- Build the selected `config.system.build.toplevel` outputs without activating
  them and without requiring `sudo`.
- Permit building configurations for machines other than the current machine;
  both physical hosts use `x86_64-linux`.

### `update`

Run `nix flake update` explicitly. Ordinary `build` and `switch` actions must
not modify `flake.lock`.

### Errors

Unknown actions, unknown hosts, empty auto-detection on an unmanaged hostname,
multi-host switch requests, and mismatched managed-host switches will print an
actionable error plus usage and return a nonzero status.

The script will resolve and enter its own repository directory so it behaves
consistently when invoked from another working directory.

## Documentation

`README.md` will document:

- the supported hostnames and directory layout;
- auto-detected and explicit switch commands;
- single-host, selected-set, and all-host build commands;
- the explicit update action;
- the fact that multi-host builds do not activate those configurations; and
- the shared local-hosts backup behavior.

## Verification

Implementation verification will include:

1. Shell syntax checking with `bash -n build.sh`.
2. Formatting and repository whitespace checks.
3. Nix flake evaluation with no lock-file mutation.
4. Evaluation of both configured hostnames.
5. A complete local build of both physical host system closures.
6. Negative routing checks for unknown hosts and multi-host switch requests,
   stopping before any activation.
7. Confirmation that the working tree contains no unintended `flake.lock` or
   local-hosts data changes.

## Acceptance criteria

- Both physical configurations evaluate and build.
- Their evaluated hostnames are distinct and match their flake names.
- GMKtec does not configure its root filesystem as swap.
- Beelink retains its real swap partition.
- Both physical hosts import `local-hosts.nix`.
- `build all` and explicit host sets build without activation.
- `switch` auto-detects a managed running host and accepts one safe explicit
  bootstrap target.
- Invalid or unsafe selector combinations fail clearly.
- Routine builds do not update `flake.lock`.
- Machine-specific files are contained within their respective host folders.
