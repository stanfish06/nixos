{
  description = "basic system setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
  };
  
  # outputs is a lamdba
  # add @inputs here so that you can access all stuffs inside inputs
  # TODO: create modules for vim, neovim, zsh
  outputs = { self, nixpkgs, nixos-wsl }@inputs: {
    # nixos is the hostname (e.g. you can have config for laptop1, desktop1, server1,...)
    # you can select specific config to rebuild with nixos-rebuild swtich --flake /etc/nixos#hostname
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # modules can import configs, install packages, enable services, etc
      # configuration.nix is just a lambda, and you can embed it here directly
      modules = [
        nixos-wsl.nixosModules.wsl
        ./configuration.nix
      ];
    };
  };
}
