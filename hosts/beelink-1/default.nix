{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-beelink-1";

  # InputCapture-capable portal stack for the Deskflow Wayland server.
  nixpkgs.overlays = [
    (final: _prev: {
      xdg-desktop-portal = final.unstable.xdg-desktop-portal;
    })
  ];

  programs.hyprland = {
    package = pkgs.unstable.hyprland;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
  };

  # Deskflow server for trusted LAN clients.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -s 192.168.8.0/24 -p tcp --dport 24800 -j nixos-fw-accept
  '';

  home-manager.users.stan =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      initialSettings = pkgs.writeText "deskflow-server-settings" ''
        [core]
        computerName=nixos-beelink-1
        coreMode=2
        port=24800
        preventSleep=false
        processMode=0

        [gui]
        autoHide=false
        closeToTray=true
        enableUpdateCheck=false
        showGenericClientFailureDialog=true
        shownServerFirstStartMessage=true
        startCoreWithGui=true

        [security]
        checkPeerFingerprints=true
        tlsEnabled=true

        [server]
        externalConfig=true
        externalConfigFile=${config.xdg.configHome}/Deskflow/deskflow-server.conf
      '';
    in
    {
      # NixOS installs Hyprland and its portal for this host.
      wayland.windowManager.hyprland = {
        package = null;
        portalPackage = null;
      };

      home.packages = [ pkgs.deskflow ];

      xdg.configFile."Deskflow/deskflow-server.conf".text = ''
        section: screens
          stanfish:
          nixos-beelink-1:
          stans-macbook-pro:
        end

        section: links
          stanfish:
            right = nixos-beelink-1
          nixos-beelink-1:
            left = stanfish
            right = stans-macbook-pro
          stans-macbook-pro:
            left = nixos-beelink-1
        end

        section: options
          clipboardSharing = false
          switchCorners = none
          switchCornerSize = 0
        end
      '';

      xdg.configFile."autostart/deskflow.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Deskflow
        Exec=${pkgs.deskflow}/bin/deskflow
        TryExec=${pkgs.deskflow}/bin/deskflow
        Terminal=false
        X-GNOME-Autostart-enabled=true
      '';

      home.activation.initializeDeskflowSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings_dir=${lib.escapeShellArg "${config.xdg.configHome}/Deskflow"}
        if [ ! -e "$settings_dir/Deskflow.conf" ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 ${initialSettings} "$settings_dir/Deskflow.conf"
        fi
      '';
    };
}
