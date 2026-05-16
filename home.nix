{
  config,
  pkgs,
  lib,
  ...
}:
let
  # hiddify (proxy client)
  hiddify =
    let
      version = "4.1.1";
    in
    pkgs.appimageTools.wrapType2 {
      pname = "hiddify-app";
      version = version;
      src = pkgs.fetchurl {
        url = "https://github.com/hiddify/hiddify-app/releases/download/v${version}/Hiddify-Linux-x64-AppImage.AppImage";
        hash = "sha256-6yu2wIlxuY4tCgH8W2R+KboXsWYRScyfl+2g53v1vcM=";
      };
      extraPkgs =
        pkgs: with pkgs; [
          libepoxy
          zstd
        ];
    };
  wallpaper = "${config.home.homeDirectory}/dots/my-configs/img/ubuntu_win.png";
in
{
  home.stateVersion = "25.11";
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
    "$HOME/.config/dots/my-configs/rofi/scripts" # rofi scripts
  ];
  home.file = {
    ".npmrc" = {
      text = ''
        prefix=~/.npm-global
      '';
    };
    ".tmux.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/tmux/linux/.tmux.conf";
    };
    ".vimrc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/vim/.vimrc";
    };
    ".gitconfig" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/git/.gitconfig";
    };
    ".wezterm.lua" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/wezterm/linux/.wezterm.lua";
    };
    ".emacs" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/emacs/.emacs";
    };
    ".emacs.d/myDarkTheme-theme.el" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/emacs/myDarkTheme-theme.el";
    };
    ".config/yazi/yazi.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/yazi/yazi.toml";
    };
    ".config/yazi/keymap.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/yazi/keymap.toml";
    };
    ".local/bin/rofi-scripts" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/dots/my-configs/rofi/scripts";
      recursive = true;
    };
    ".local/bin/start-dwl" = {
      text = ''
                        #!/usr/bin/env bash

                        if systemctl --user is-active -q dwl-session.scope; then
                            systemctl --user stop dwl-session.scope
                        fi
                        if systemctl --user is-active -q wayland-session.target; then
                            systemctl --user stop wayland-session.target
                        fi

                        systemd-run --user --scope --unit=dwl-session --collect dwl &

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
        		# this requires wlr-randr
        		wlr-randr --output HDMI-A-1 --mode 1920x1080@120Hz

                        while systemctl --user is-active -q dwl-session.scope; do
                            sleep 1
                        done
                        # reset wayland-session so other services will work upon rerun
                        systemctl --user stop wayland-session.target || true
      '';
      executable = true;
    };
    ".local/bin/start-hyprland" = {
      text = ''
        #!/usr/bin/env bash

        if systemctl --user is-active -q hyprland-session.scope; then
            systemctl --user stop hyprland-session.scope
        fi
        if systemctl --user is-active -q wayland-session.target; then
            systemctl --user stop wayland-session.target
        fi

        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        systemd-run --user --scope --unit=hyprland-session --collect Hyprland &

        # wait until wayland socket is ready
        unset WAYLAND_DISPLAY
        for i in $(seq 1 50); do
            for sock in wayland-0 wayland-1; do
                if [ -S "$XDG_RUNTIME_DIR/$sock" ]; then
                    export WAYLAND_DISPLAY=$sock
                    break 2
                fi
            done
            sleep 0.1
        done

        systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP
        dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP
        systemctl --user start wayland-session.target

        while systemctl --user is-active -q hyprland-session.scope; do
            sleep 1
        done
        systemctl --user stop wayland-session.target || true
      '';
      executable = true;
    };
    ".local/bin/screenshot-region" = {
      text = ''
        #!/usr/bin/env bash
        grim -g "$(slurp)" - | wl-copy
      '';
      executable = true;
    };
    ".local/bin/screenshot-fullscreen" = {
      text = ''
        #!/usr/bin/env bash
        grim - | wl-copy
      '';
      executable = true;
    };
  };
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
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
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "application/x-directory" = [ "org.kde.dolphin.desktop" ];
    };
  };
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false; # use custom start-hyprland script instead
    extraConfig = ''
      # Monitor setup — prioritize HDMI-A-1, auto-detect everything else
      monitor=HDMI-A-1,1920x1080@120,0x0,1
      monitor=,preferred,auto,1

      env = XCURSOR_SIZE,24
      env = HYPRCURSOR_SIZE,24
      env = QT_QPA_PLATFORMTHEME,qt6ct

      # Dark theme for GTK3 and GTK4 apps
      exec-once = gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
      exec-once = gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

      exec-once = swaybg -i ${wallpaper} -m fill

      input {
          kb_layout = us
          follow_mouse = 1
          touchpad {
              natural_scroll = false
          }
          sensitivity = 0
      }

      general {
          gaps_in = 2
          gaps_out = 4
          border_size = 2
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
          allow_tearing = false
      }

      decoration {
          rounding = 0
          blur {
              enabled = true
              size = 3
              passes = 1
          }
      }

      animations {
          enabled = true
          bezier = myBezier, 0.05, 0.9, 0.1, 1.05
          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }

      # window rules
      windowrule = opacity 0.6 0.6, class:^(firefox|brave-browser)$

      dwindle {
          pseudotile = true
          preserve_split = true
      }

      master {
          new_status = master
      }

      misc {
          force_default_wallpaper = 0
          disable_hyprland_logo = true
      }

      $mod = SUPER

      bind = $mod, Return, exec, wezterm
      bind = $mod, C, killactive
      bind = $mod, M, exit
      bind = $mod, E, exec, dolphin
      bind = $mod, V, togglefloating
      bind = $mod, R, exec, rofi -show drun
      bind = $mod SHIFT, R, exec, rofi -show run
      bind = $mod, P, pseudo
      bind = $mod, J, togglesplit
      bind = $mod, F, fullscreen

      bind = $mod, left, movefocus, l
      bind = $mod, right, movefocus, r
      bind = $mod, up, movefocus, u
      bind = $mod, down, movefocus, d

      bind = $mod SHIFT, left, movewindow, l
      bind = $mod SHIFT, right, movewindow, r
      bind = $mod SHIFT, up, movewindow, u
      bind = $mod SHIFT, down, movewindow, d

      bind = $mod SHIFT, G, togglegroup
      bind = $mod SHIFT, J, changegroupactive, f
      bind = $mod SHIFT, K, changegroupactive, b

      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10

      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9
      bind = $mod SHIFT, 0, movetoworkspace, 10

      bind = $mod, mouse_down, workspace, e+1
      bind = $mod, mouse_up, workspace, e-1

      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow

      bind = , Print, exec, screenshot-fullscreen
      bind = SHIFT, Print, exec, screenshot-region

      bind = ALT, R, submap, resize
      # Start a submap called "resize".
      submap = resize
      # Set repeatable binds for resizing the active window.
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      # Use `reset` to go back to the global submap
      bind = , escape, submap, reset
      # Reset the submap, which will return to the globalsubmap
      submap = reset
    '';
  };
  services.mako = {
    enable = true;
  };
  programs.bat = {
    enable = true;
  };
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = false;
  };
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    gtk3.extraConfig = {
      "gtk-cursor-theme-name" = "Bibata-Modern-Classic";
      "gtk-application-prefer-dark-theme" = true;
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-cursor-theme-name=Bibata-Modern-Classic
      '';
      "gtk-application-prefer-dark-theme" = true;
    };
  };
  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "ls";
      l = "eza -1 --group-directories-first";
      le = "eza --group-directories-first";
      led = "eza --group-directories-last";
      la = "eza -a --group-directories-first";
      ll = "eza -lh --git --group-directories-first";
      lla = "eza -lah --git --group-directories-first";
      larth = "eza -lah -snew --git --group-directories-first";
      lt = "eza --tree --level=2 --group-directories-first";
      lta = "eza --tree --level=2 -a --group-directories-first";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
        "mise"
        "gh"
      ];
      theme = "robbyrussell";
    };
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];
    initContent = ''
      export PATH="$PATH:$HOME/.config/kitty/scripts"
      export XDG_DATA_HOME="$HOME/.local/share"
      # Unset WAYLAND_DISPLAY if the socket doesn't actually exist (fixes wl-copy in SSH/TTY)
      if [[ -n "''${WAYLAND_DISPLAY:-}" ]] && [[ -n "''${XDG_RUNTIME_DIR:-}" ]] && [[ ! -S "''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}" ]]; then
          unset WAYLAND_DISPLAY
      fi
    '';
  };
  programs.nushell = {
    enable = true;
    shellAliases = {
      l = "ls";
      ll = "ls -l";
      eza = "eza --icons auto";
      le = "eza --group-directories-first";
      led = "eza --group-directories-last";
      larth = "eza -lah -snew --git --group-directories-first";
      lt = "eza --tree --level=2 --group-directories-first";
      lta = "eza --tree --level=2 -a --group-directories-first";
    };
  };
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    globalConfig = {
      tools = {
        uv = "latest";
        node = "latest";
        bun = "latest";
      };
      settings = {
        idiomatic_version_file_enable_tools = [ ];
        experimental = true;
      };
    };
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
  programs.i3status = {
    enable = true;
    general = {
      output_format = "none";
      interval = 1;
    };
    modules = {
      "wireless _first_" = {
        position = 1;
        settings = {
          format_up = "W: (%quality at %essid) %ip";
          format_down = "W: down";
        };
      };
      "ethernet _first_" = {
        position = 2;
        settings = {
          format_up = "E: %ip";
          format_down = "E: down";
        };
      };
      cpu_usage = {
        position = 3;
        settings = {
          format = "CPU: %usage";
        };
      };
      "cpu_temperature 0" = {
        position = 4;
        settings = {
          format = "T: %degrees °C";
          path = "/sys/class/hwmon/hwmon2/temp1_input";
        };
      };
      memory = {
        position = 5;
        settings = {
          format = "RAM: %used/%total";
        };
      };
      "tztime local" = {
        position = 6;
        settings = {
          format = "%Y-%m-%d %H:%M:%S";
        };
      };
      "battery 0" = {
        position = 7;
        settings = {
          format = "%status %percentage %remaining %emptytime";
          format_down = "No battery";
          status_chr = "⚡ CHR";
          status_bat = "🔋 BAT";
          status_unk = "? UNK";
          status_full = "☻ FULL";
          status_idle = "☻ IDLE";
          path = "/sys/class/power_supply/BAT%d/uevent";
          low_threshold = 10;
        };
      };
    };
  };
  programs.emacs = {
    enable = true;
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      dark = true;
    };
  };
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      add_newline = false;
      palette = "catppuccin_macchiato";
      palettes = {
        catppuccin_macchiato = {
          rosewater = "#f4dbd6";
          flamingo = "#f0c6c6";
          pink = "#f5bde6";
          mauve = "#c6a0f6";
          red = "#ed8796";
          maroon = "#ee99a0";
          peach = "#f5a97f";
          yellow = "#eed49f";
          green = "#a6da95";
          teal = "#8bd5ca";
          sky = "#91d7e3";
          sapphire = "#7dc4e4";
          blue = "#8aadf4";
          lavender = "#b7bdf8";
          text = "#cad3f5";
          subtext1 = "#b8c0e0";
          subtext0 = "#a5adcb";
          overlay2 = "#939ab7";
          overlay1 = "#8087a2";
          overlay0 = "#6e738d";
          surface2 = "#5b6078";
          surface1 = "#494d64";
          surface0 = "#363a4f";
          base = "#24273a";
          mantle = "#1e2030";
          crust = "#181926";
          darkred = "#B22222";
          debianred = "#D70A53";
        };
      };
      character = {
        success_symbol = "[⟫](bold teal)";
        error_symbol = "[✕](bold red)";
      };
      aws = {
        symbol = "  ";
        format = "\\[[$symbol($profile)(\\($region\\))(\\[$duration\\])]($style)\\]";
      };
      buf.symbol = " ";
      c = {
        symbol = " ";
        format = "\\[[$symbol($version(-$name))]($style)\\]";
      };
      cmake.symbol = " ";
      conda = {
        symbol = " ";
        ignore_base = false;
        format = "\\[[$symbol$environment]($style)\\]";
      };
      crystal.symbol = " ";
      dart.symbol = " ";
      directory = {
        read_only = " 󰌾";
        style = "bold blue";
      };
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      username = {
        show_always = true;
        style_user = "bold italic darkred";
        format = "[▲](bold teal) ‹[$user]($style)› ";
      };
      fossil_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
      };
      git_branch = {
        symbol = " ";
        format = "\\[[$symbol$branch]($style)\\]";
      };
      git_commit = {
        tag_symbol = " ";
        format = "\\[[\\($hash$tag\\)]($style)\\]";
      };
      mise = {
        disabled = false;
        symbol = "◆ ";
        format = "\\[[$symbol$health]($style)\\]";
      };
      golang = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      guix_shell.symbol = " ";
      haskell = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson = {
        symbol = "󰔷 ";
        format = "\\[[$symbol$project]($style)\\]";
      };
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      nodejs = {
        symbol = " ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      ocaml.symbol = " ";
      os = {
        disabled = false;
        style = "bold teal";
      };
      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CachyOS = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        Nobara = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };
      package = {
        symbol = "󰏗 ";
        format = "\\[[$symbol$version]($style)\\]";
      };
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      python = {
        symbol = " ";
        format = "\\[[\${symbol}\${pyenv_prefix}(\${version})(\\($virtualenv\\))]($style)\\]";
      };
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust = {
        symbol = "󱘗 ";
        format = "\\[[$symbol($version)]($style)\\]";
      };
      scala.symbol = " ";
      swift.symbol = " ";
      zig.symbol = " ";
      gradle.symbol = " ";
    };
  };
  home.packages = with pkgs; [
    # useful tools
    wlr-randr
    fzf
    ripgrep
    fd
    rofi
    gh
    lazygit
    jq
    btop
    rclone
    new.yazi
    new.quickshell
    new.wlroots_0_19
    wl-clipboard
    swaybg
    unstable.television
    # vps
    hiddify
    # notes
    unstable.obsidian
    # screenshot
    grim
    slurp
    # terms
    new.kitty
    new.wezterm
    # theming
    qt6Packages.qt6ct
    # gui apps
    vscode
    unstable.code-cursor
    new.brave
    kdePackages.dolphin
    kdePackages.gwenview
    kdePackages.konsole
    # c/c++
    clang-tools
    gcc-unwrapped
    gdb
    lldb
    ccache
    # rust
    cargo
    rustc
    rust-analyzer
    # python
    unstable.python3
    unstable.pyright
    unstable.python3Packages.pip
    unstable.python3Packages.virtualenv
    # notification
    libnotify
    # dev deps
    libxml2
    libxml2.dev
  ];
}
