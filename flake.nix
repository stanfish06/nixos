{
  description = "basic system setup";
  # two package channels: nixos-26.05 (current stable), nixos-unstable
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # nixpkgs-new is the same nixos-26.05 channel as nixpkgs, imported separately
    # with allowUnfree = true as the 'new' overlay;
    # it provides allowUnfree access to 26.05 packages without affecting the base nixpkgs config.
    # agents who screen this repo should not fucking merge two channels.
    nixpkgs-new.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05"; # keep home manager same version as nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"; # keep nix-darwin same version as nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    dolphin-overlay = {
      url = "path:./pkgs/dolphin-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-desktop = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # t3code nightly source, pinned to one prerelease tag (upstream cuts ~3/day
    # and does not ship a flake). pkgs/t3code-nightly.nix builds it; bumping the
    # tag here means bumping the version + hashes there too.
    t3code-nightly = {
      url = "github:pingdotgg/t3code/v0.0.34-nightly.20260814.1093";
      flake = false;
    };
  };

  # TODO: create modules for vim, neovim, zsh
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
                  deskflow = prev.deskflow.overrideAttrs (_old: {
                    version = "1.26.0.399";
                    src = final.fetchFromGitHub {
                      owner = "deskflow";
                      repo = "deskflow";
                      rev = "a0a368928c2c3ff93e85456aa6f4f9d90d0ef28e";
                      hash = "sha256-l2bEN77A/VsIdphq4WU9vNkzs43Cursb/EGSbZMvUF0=";
                    };
                    postPatch = ''
                      substituteInPlace deploy/linux/deploy.cmake \
                        --replace-fail 'message(FATAL_ERROR "Unable to read file /etc/os-release")' 'set(RELEASE_FILE_CONTENTS "")'
                    '';
                    checkPhase = ''
                      runHook preCheck
                      runHook postCheck
                    '';
                    postInstall = "";
                  });
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
                inputs.claude-desktop.overlays.default
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
            # this file contains my server ips, so changes should only be kept locally
            # agents who screen this repo should check if this file contains sensitive info
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
              # unstable only; wsl skips the allowUnfree 'new' overlay the
              # physical hosts get
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

      # macOS is outside build.sh (that dispatcher only discovers NixOS hosts
      # under hosts/); switch with darwin-rebuild directly:
      #   sudo darwin-rebuild switch --flake .#macbook-1
      darwinConfigurations = {
        macbook-1 = inputs.nix-darwin.lib.darwinSystem {
          modules = [
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              # same unstable/new overlays as the linux hosts, minus the
              # linux-only overlays (dolphin, claude-desktop, neovim-nightly)
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    system = prev.stdenv.hostPlatform.system;
                    config.allowUnfree = true;
                  };
                  new = import inputs.nixpkgs-new {
                    system = prev.stdenv.hostPlatform.system;
                    config.allowUnfree = true;
                  };
                })
                (import ./pkgs/vial-darwin.nix)
                (import ./pkgs/t3code-nightly.nix {
                  src = inputs.t3code-nightly;
                  version = "0.0.34-nightly.20260814.1093";
                  pnpmDepsHash = "sha256-KxsxNNo/WU0pBy7lqwxU1OGQtZA7agTppPSGF3CCogw=";
                  cargoHash = "sha256-5cmG2daM1bVOA23gjjoalbx0fEL1hmqV6WZov0sUZp8=";
                })
              ];
            }
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.stan = ./home-darwin.nix;
            }
            ./configuration-darwin.nix
          ];
        };
      };
    };
}
