# NixOS configuration

This flake manages two physical NixOS hosts, retains the WSL configuration,
and carries a draft nix-darwin profile for the MacBook (see
[macOS](#macos-nix-darwin) below).

| Selector | Hostname / flake output | Host module |
| --- | --- | --- |
| `beelink-1` | `nixos-beelink-1` | `hosts/beelink-1/` |
| `gmktec-1` | `nixos-gmktec-1` | `hosts/gmktec-1/` |

Shared physical-host configuration stays in `configuration-linux.nix` and
`home.nix`. Each host module supplies its hostname and hardware configuration.
Both physical hosts import the root `local-hosts.nix`; WSL continues to use its
separate configuration. `build.sh` discovers only physical hosts under
`hosts/`; the WSL flake output is outside this dispatcher.

## Build and switch

Switch the current managed host by auto-detecting its hostname:

```bash
./build.sh switch
```

Select a host explicitly, including when bootstrapping a machine:

```bash
./build.sh switch beelink-1
./build.sh switch gmktec-1
```

On an unmanaged hostname, an explicit selector is an override with no hardware
identity check. Run `./build.sh build <host>` before the first switch. If the
current hostname identifies a managed host, switching to a different managed
host is rejected; unknown names in the `nixos-*` namespace fail closed.
`switch` accepts at most one selector.

Build one or more system closures without activating them:

```bash
./build.sh build
./build.sh build beelink-1
./build.sh build beelink-1 gmktec-1
./build.sh build all
```

With no selector, `build` auto-detects the current managed hostname. Multi-host
builds only build closures in the local Nix store; they do not activate or
deploy configurations to other machines.

If switch through ssh, spawn a tmux server first then switch inside of it.

## macOS (nix-darwin)

`darwinConfigurations.macbook-1` manages the Apple Silicon MacBook with
[nix-darwin](https://github.com/nix-darwin/nix-darwin);
`configuration-darwin.nix` and `home-darwin.nix` hold the system and
home-manager halves. `build.sh` only dispatches NixOS hosts, so use
darwin-rebuild directly. Bootstrap after installing Nix:

```bash
nix flake lock
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#macbook-1
```

Subsequent switches:

```bash
sudo darwin-rebuild switch --flake .#macbook-1
```

Casks without a nixpkgs equivalent stay in Homebrew, declared under
`homebrew.casks` in `configuration-darwin.nix`;
`homebrew.onActivation.cleanup = "none"` keeps existing brew installs
untouched while the migration is in progress.

Routine `build` and `switch` commands do not write `flake.lock`. Update locked
inputs explicitly:

```bash
./build.sh update
```

## Private host mappings

The committed root `local-hosts.nix` is an empty dummy. Keep the private state
backup as the source of truth:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix
```

Before editing that backup, run `./run-before-commit.sh` to save any current
root mappings and restore the dummy. Then edit the backup. Before building or
switching either physical host, `build.sh` restores it into the root file.

If you instead edit the root `local-hosts.nix`, run
`./run-before-commit.sh` before building or switching. It saves the divergent
private mappings and sanitizes the root file; `build.sh` refuses to overwrite
divergent unsaved mappings with the backup.

## Before committing

Use this workflow:

```bash
./run-before-commit.sh
git add . &&
  git status --short &&
  git diff --cached --quiet -- local-hosts.nix &&
  git commit -m "..." &&
  git push
```

`run-before-commit.sh` formats the repository, saves private mappings when the
working tree or index differs from `HEAD`, and restores the committed empty
dummy to both places. When the root file already matches the dummy, it retains
an existing backup instead of replacing it. Review the staged status before
committing. The quiet check emits no file contents; exit status 0 means
`local-hosts.nix` is not staged differently from `HEAD`. If staging or that
check fails, the `&&` chain prevents the commit and push. If staged and working
private mappings conflict, `run-before-commit.sh` stops before changing either
copy or the backup; reconcile them and rerun it.
