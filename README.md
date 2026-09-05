# NixOS configuration

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

Build one or more system closures without activating them:

```bash
./build.sh build
./build.sh build beelink-1
./build.sh build beelink-1 gmktec-1
./build.sh build all
```

## macOS (nix-darwin)

```bash
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#macbook-1
```

Subsequent switches:

```bash
sudo darwin-rebuild switch --flake .#macbook-1
```
