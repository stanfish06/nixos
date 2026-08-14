# t3code nightly channel.
#
# Upstream (pingdotgg/t3code) cuts prerelease tags ~3x/day and there is no
# community nightly overlay flake, so this rebuilds nixpkgs' own t3code recipe
# against the tag pinned by the `t3code-nightly` flake input. The nixpkgs
# wrapper is kept (t3 CLI, git/gh/codex on PATH, resource-monitor sidecar).
#
# Bumping: point the input at a newer tag in flake.nix, set `version` to that
# tag without its leading "v", then refresh the two hashes below -- set one to
# lib.fakeHash at a time, build, and copy the hash nix reports as "got:".
{
  src,
  version,
  pnpmDepsHash,
  cargoHash,
}:
final: prev: {
  t3code-nightly =
    let
      unwrapped = final.unstable.t3code.unwrapped.overrideAttrs (prevAttrs: {
        inherit src version;
        # pnpmDeps already tracks the new src through finalAttrs, so only its
        # output hash has to be replaced
        pnpmDeps = prevAttrs.pnpmDeps.overrideAttrs { outputHash = pnpmDepsHash; };
        # upstream derives this from src.tag, which a flake input source lacks
        meta = prevAttrs.meta // {
          changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${version}";
        };
      });

      # the sidecar is a separate rust crate in the same tree; its sourceRoot
      # normally comes from src.name, unavailable on a flake input source
      resourceMonitor = final.unstable.t3code.resourceMonitor.overrideAttrs {
        inherit src version cargoHash;
        sourceRoot = "source/native/resource-monitor";
      };
    in
    final.unstable.t3code.override {
      t3code-unwrapped = unwrapped;
      t3code-resource-monitor = resourceMonitor;
    };
}
