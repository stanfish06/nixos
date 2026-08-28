{ config, pkgs, ... }:
{
  imports = [
    ./modules/miniflux-darwin.nix
    ./modules/apple-container-darwin.nix
  ];

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
      {
        name = "deskflow/homebrew-tap";
        trusted = true;
      }
      "manaflow-ai/cmux"
    ];
    casks = [
      "cmux"
      "codexbar"
      "copilot-cli"
      "deskflow-dev"
      "helium-browser"
      "miniconda"
      "raycast"
    ];
  };

  environment.systemPackages = [ pkgs.unstable.container ];

  launchd.user.agents.aerospace = {
    command = "${pkgs.unstable.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace";
    path = [
      "/etc/profiles/per-user/stan/bin"
      config.environment.systemPath
    ];
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  launchd.user.agents.deskflow = {
    serviceConfig = {
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "Deskflow"
      ];
      RunAtLoad = true;
    };
  };

  system.stateVersion = 6;
}
