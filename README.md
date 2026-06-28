# NixOS configuration

This flake manages two physical NixOS hosts and retains the WSL configuration.

| Selector | Hostname / flake output | Host module |
| --- | --- | --- |
| `beelink-1` | `nixos-beelink-1` | `hosts/beelink-1/` |
| `gmktec-1` | `nixos-gmktec-1` | `hosts/gmktec-1/` |

Shared physical-host configuration stays in `configuration-linux.nix` and
`home.nix`. Each host module supplies its hostname and hardware configuration.
Both physical hosts import the root `local-hosts.nix`; WSL continues to use its
separate configuration.

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

If the current hostname already identifies a managed host, switching to a
different managed host is rejected. `switch` accepts only one host.

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

Routine `build` and `switch` commands do not write `flake.lock`. Update locked
inputs explicitly:

```bash
./build.sh update
```

## Private host mappings

The committed `local-hosts.nix` is an empty dummy. Before building or switching
either physical host, `build.sh` restores a private copy when one exists at:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/nixos/local-hosts.nix
```

Edit the working copy of `local-hosts.nix` when private host mappings change.

## Before committing

Use this workflow:

```bash
./run-before-commit.sh
git add .
git commit -m "..."
git push
```

`run-before-commit.sh` formats the repository, saves the private mappings to the
state path above, and restores the committed empty dummy before the commit.
