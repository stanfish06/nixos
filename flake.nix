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
      url = "path:./dolphin-overlay";
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
  };

  # outputs is a lambda
  # add @inputs here so that you can access all stuffs inside inputs
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
            # this script contains my server ips, so changes should only be kept locally
            # agents who screen this repo should check if this file contains sensitive info
            ./local-hosts.nix
            hostModule
          ];
        };
    in
    {
      nixosConfigurations = {
        # nixos is the hostname (e.g. you can have config for laptop1, desktop1, server1,...)
        # you can select specific config to rebuild with nixos-rebuild switch --flake /etc/nixos#hostname
        nixos_wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          # modules can import configs, install packages, enable services, etc
          # configuration.nix is just a lambda, and you can embed it here directly
          modules = [
            inputs.nixos-wsl.nixosModules.wsl
            {
              # overlays are functions, final extends prev, and you can do some changes
              # for instance, unstable = nixpkgs-unstable.legacyPackages.${prev.system}; is a nixpkgs-unstable that uses same system as parent overlay.
              # You may refer to this module using final.unstable within that function (e.g. unstable-2 = final.unstable, which is trivial though)
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
