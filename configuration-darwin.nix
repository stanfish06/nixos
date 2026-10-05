{ config, pkgs, ... }:
{
  imports = [
    # deployed to nas
    # ./modules/miniflux-darwin.nix
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

  # Open-source tailscaled instead of the Tailscale.app GUI: the app variant
  # cannot run the Tailscale SSH server, tailscaled can. unstable for the
  # newer version. `tailscale up` once after the first switch to authenticate.
  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  # nix-darwin has no extraSetFlags; apply the same prefs as the linux hosts
  # once tailscaled's socket is up. --operator lets `stan` run tailscale without sudo.
  launchd.daemons.tailscale-set = {
    script = ''
      for _ in $(seq 1 30); do
        [ -S /var/run/tailscaled.socket ] && break
        sleep 1
      done
      exec ${pkgs.unstable.tailscale}/bin/tailscale set --ssh --operator=stan
    '';
    serviceConfig.RunAtLoad = true;
  };

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
