{ config, pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.zsh.enable = true;

  users.users.stan = {
    name = "stan";
    home = "/Users/stan";
  };
  system.primaryUser = "stan";

  security.pam.services.sudo_local.touchIdAuth = true;

  fonts.packages = with pkgs; [
    iosevka
    nerd-fonts.iosevka
    nerd-fonts.victor-mono
    nerd-fonts.zed-mono
    maple-mono.NF
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    taps = [
      "manaflow-ai/cmux"
    ];
    casks = [
      "cmux"
      "codexbar"
      "copilot-cli"
      "miniconda"
    ];
  };

  # not services.aerospace: that module always passes a nix-generated
  # --config-path, ignoring the chezmoi-managed ~/.config/aerospace config.
  # systemPath on PATH so exec-and-forget/exec-on-workspace-change resolve
  # sketchybar and lua from the nix profiles.
  launchd.user.agents.aerospace = {
    command = "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
    path = [ config.environment.systemPath ];
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  system.stateVersion = 6;
}
