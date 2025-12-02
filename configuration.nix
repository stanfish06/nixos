# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
    # <nixos-wsl/modules>
  ];

  wsl.enable = true;
  wsl.defaultUser = "nixos";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.zsh.enable = true;
  users.users.nixos = {
    isNormalUser = true;
    shell = pkgs.zsh;
    initialPassword = "123456";
  };
  users.users.root = {
    initialPassword = "123456";
  };

  environment.systemPackages = with pkgs; [
    # basic tools
    git
    vim
    wget
    curl
    # build tools
    gcc
    gnumake
    cmake
    pkg-config
    autoconf
    automake
    libtool
    # others that can be as new as possible
    unstable.tmux
    unstable.zsh
    unstable.neovim
  ];
  environment.variables.EDITOR = "vim";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment? Do not touch this.
}
