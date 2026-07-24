{ pkgs, ... }:
{
  # nix-darwin system configuration for the macbook (draft).
  #
  # Bootstrap (after installing nix itself):
  #   nix flake lock   # add the new nix-darwin input to flake.lock
  #   sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#macbook-1
  # Subsequent switches:
  #   sudo darwin-rebuild switch --flake .#macbook-1

  # If nix was installed with the Determinate installer, it manages the nix
  # daemon itself and conflicts with nix-darwin doing it too; uncomment:
  # nix.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # make /etc/zshrc source the nix environment (zsh is the macOS login shell)
  programs.zsh.enable = true;

  users.users.stan = {
    name = "stan";
    home = "/Users/stan";
  };
  # user-scoped options (homebrew, system.defaults, ...) apply to this user
  system.primaryUser = "stan";

  # touch id for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # replaces the font-* casks
  fonts.packages = with pkgs; [
    iosevka
    nerd-fonts.iosevka
    nerd-fonts.victor-mono
    nerd-fonts.zed-mono
    maple-mono.NF
  ];

  # casks without a good nixpkgs equivalent stay in homebrew, managed
  # declaratively. nix-darwin drives an existing brew install; it does not
  # install brew itself.
  homebrew = {
    enable = true;
    # "none" never uninstalls anything while the brew -> nix migration is in
    # progress; tighten to "uninstall"/"zap" once brew only owns this list.
    onActivation.cleanup = "none";
    taps = [
      "manaflow-ai/cmux"
    ];
    casks = [
      "cmux"
      "codexbar"
      "copilot-cli" # nixpkgs only carries the deprecated github-copilot-cli
      "miniconda" # conda under nix is painful; nix alternative: pkgs.micromamba
      # stable kitty/wezterm come from nixpkgs (home-darwin.nix); keep the
      # nightlies in brew if they are still wanted:
      "kitty@nightly"
      "wezterm@nightly"
    ];
  };

  # aerospace and sketchybar are installed from nixpkgs in home-darwin.nix.
  # nix-darwin can also run them as launchd services against the existing
  # dotfile configs; enable only after removing the brew-managed copies so
  # they do not double-start:
  # services.aerospace.enable = true;
  # services.sketchybar.enable = true;

  # macos defaults can be managed declaratively too, e.g.:
  # system.defaults.dock.autohide = true;
  # system.defaults.NSGlobalDomain.KeyRepeat = 2;

  # used for backwards compatibility; check `darwin-rebuild changelog`
  # before changing
  system.stateVersion = 6;
}
