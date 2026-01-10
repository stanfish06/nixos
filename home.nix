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

        while systemctl --user is-active -q dwl-session.scope; do
            sleep 1
        done
        # reset wayland-session so other services will work upon rerun
        systemctl --user stop wayland-session.target || true
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
        "mise"
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
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
  };
  programs.starship = {
    enable = true;
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
        symbol = "";
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
        symbol = " ";
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
    fzf
    ripgrep
    rofi-wayland
    gh
    i3status
    lazygit
    vscode
    rstudio
    jq
    btop
    rclone
    new.atuin
    new.quickshell
    new.wezterm
    new.wlroots_0_19
    new.brave
    new.mise
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
    # js
    unstable.nodejs
    unstable.nodePackages.bash-language-server
    # bulid tools
    pkg-config
    autoconf
    automake
    libtool
  ];
}
