{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos-gmktec-1";

  home-manager.users.stan =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      initialSettings = pkgs.writeText "deskflow-client-settings" ''
        [client]
        remoteHost=192.168.8.222,nixos-beelink-1.local

        [core]
        computerName=nixos-gmktec-1
        coreMode=1
        port=24800
        preventSleep=false
        processMode=0

        [gui]
        autoHide=false
        closeToTray=true
        enableUpdateCheck=false
        showGenericClientFailureDialog=true
        startCoreWithGui=true

        [security]
        checkPeerFingerprints=true
        tlsEnabled=true
      '';
    in
    {
      home.packages = [ pkgs.deskflow ];

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
