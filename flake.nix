{
  description = "basic system setup";
  # enable both stable and unstable package indices
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
  };
  
  # outputs is a lamdba
  # add @inputs here so that you can access all stuffs inside inputs
  # TODO: create modules for vim, neovim, zsh
  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-wsl }@inputs: {
    # nixos is the hostname (e.g. you can have config for laptop1, desktop1, server1,...)
    # you can select specific config to rebuild with nixos-rebuild swtich --flake /etc/nixos#hostname
    nixosConfigurations.nixos_wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # modules can import configs, install packages, enable services, etc
      # configuration.nix is just a lambda, and you can embed it here directly
      modules = [
        nixos-wsl.nixosModules.wsl
        {
          # overlays are functions, final extends prev, and you can do some changes
          # for instance, unstable = nixpkgs-unstable.legacyPackages.${prev.system}; is a nixpkgs-unstable that uses same system as parent overlay.  
          # You may refer to this module using final.unstable within that function (e.g. unstable-2 = final.unstable, which is trivial though)
          nixpkgs.overlays = [
            (final: prev: {
               unstable = nixpkgs-unstable.legacyPackages.${prev.system};           
            })
          ];
        }
        ./configuration-wsl.nix
      ];
    };
    nixosConfigurations.nixos_linux = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev: {
               unstable = nixpkgs-unstable.legacyPackages.${prev.system};           
            })
          ];
        }
        ./configuration-linux.nix
        /etc/nixos/hardware-configuration.nix
      ];
    };
  };
}
