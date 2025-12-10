{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.stateVersion = "24.05";

  home.file = {
    ".tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/tmux/linux/.tmux.conf";
    };
    ".local/bin/start-dwl" = {
      text = ''
        #!/usr/bin/env bash

        dwl &
        # wait until socket is ready, then start services
        unset WAYLAND_DISPLAY
        while [ -z "$WAYLAND_DISPLAY" ]; do 
            sleep 0.1
            export WAYLAND_DISPLAY=wayland-0
            if [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
                echo "socket found"
                break
            fi
            unset WAYLAND_DISPLAY
        done

        systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        systemctl --user start wayland-session.target
      '';
      executable = true;
    };
  };
  systemd.user.targets.wayland-session = {
    Unit = {
      Description = "Wayland compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };
  systemd.user.services.quickshell = {
    Unit = {
      Description = "QuickShell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.new.quickshell}/bin/quickshell";
      Restart = "on-failure";
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };
    Install = {
      WantedBy = [ "wayland-session.target" ];
    };
  };
  xdg.configFile = {
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/nvim";
      recursive = true;
    };
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
      ];
      theme = "robbyrussell";
    };
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };
  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };
  home.packages = with pkgs; [
    fzf
    ripgrep
    rofi-wayland
    gh
    i3status
    lazygit
    new.quickshell
  ];
}
