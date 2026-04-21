{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.stateVersion = "24.05";
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
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
  services.mako = {
    enable = true;
  };
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = false;
  };
  programs.television = {
    enable = true;
    enableZshIntegration = true;
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
      eval "$(mise activate zsh)"
      export PATH="$PATH:$HOME/.config/kitty/scripts"
      export XDG_DATA_HOME="$HOME/.local/share"
    '';
  };
  programs.nushell = {
    enable = true;
  };
  programs.atuin = {
    enable = true;
    package = pkgs.new.atuin;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    package = pkgs.new.zoxide;
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
    rofi-wayland
    gh
    i3status
    lazygit
    jq
    btop
    rclone
    new.yazi
    new.quickshell
    new.wlroots_0_19
    new.mise
    wl-clipboard
    # screenshot
    grim
    slurp
    # terms
    new.kitty
    new.wezterm
    # gui apps
    vscode
    unstable.code-cursor
    new.brave
    # c/c++
    clang-tools
    gcc
    cmake
    gnumake
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
    # build tools
    pkg-config
    autoconf
    automake
    libtool
    # notification
    libnotify
    # dev deps
    libxml2
    libxml2.dev
  ];
}
