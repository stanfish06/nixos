{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  initialDeskflowSettings = pkgs.writeText "deskflow-client-settings" ''
    [client]
    remoteHost=192.168.8.222

    [core]
    computerName=stans-macbook-pro
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
  # .app bundle that opens the url as a Helium app window; LSUIElement keeps the
  # launcher itself out of the Dock since it exits right after `open`
  mkWebApp =
    id:
    {
      name,
      url,
      icon,
    }:
    let
      infoPlist = pkgs.writeText "Info.plist" (
        lib.generators.toPlist { escape = true; } {
          CFBundleExecutable = id;
          CFBundleIconFile = "icon";
          CFBundleIdentifier = "dev.stan.webapp.${id}";
          CFBundleName = name;
          CFBundlePackageType = "APPL";
          LSUIElement = true;
        }
      );
    in
    pkgs.runCommand "web-app-${id}"
      {
        nativeBuildInputs = [
          pkgs.librsvg
          pkgs.libicns
        ];
      }
      ''
        contents="$out/Applications/${name}.app/Contents"
        mkdir -p "$contents/MacOS" "$contents/Resources"
        cp ${infoPlist} "$contents/Info.plist"
        for size in 16 32 128 256 512; do
          rsvg-convert -w $size -h $size ${icon} -o icon_$size.png
        done
        png2icns "$contents/Resources/icon.icns" icon_*.png
        # -n starts a second Helium process that hands --app to the running one
        cat > "$contents/MacOS/${id}" <<'EOF'
        #!/bin/sh
        exec /usr/bin/open -na Helium --args --app=${lib.escapeShellArg url}
        EOF
        chmod +x "$contents/MacOS/${id}"
      '';
in
{
  home.stateVersion = "26.05";

  home.file.".raycast-scripts/flameshot.sh" = {
    text = ''
      #!/bin/bash

      # @raycast.schemaVersion 1
      # @raycast.title Flameshot
      # @raycast.mode silent
      # @raycast.icon 📸
      # @raycast.packageName Screenshot

      exec ${pkgs.unstable.flameshot}/bin/flameshot gui
    '';
    executable = true;
  };

  home.activation.initializeDeskflowSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir=${lib.escapeShellArg "${config.home.homeDirectory}/Library/Deskflow"}
    if [ ! -e "$settings_dir/Deskflow.conf" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 ${initialDeskflowSettings} "$settings_dir/Deskflow.conf"
    fi
  '';

  home.packages =
    with pkgs;
    [
      # shell + cli; atuin/bat/eza/fd/fzf/jq/ripgrep/zoxide/gh come from mise
      autossh
      btop
      chafa
      chezmoi
      clipboard-jh # brew calls this "clipboard"
      coreutils
      mosh
      television
      yazi
      worktrunk
      # git
      lazygit
      # agent sandboxes
      new.docker-sbx
      # terminal multiplexing
      tmux
      sesh
      # prompt + shells
      starship
      nushell
      # zsh; .zshrc from chezmoi sources these from /etc/profiles/per-user/stan/share
      oh-my-zsh
      zsh-vi-mode
      zsh-autosuggestions
      zsh-syntax-highlighting
      direnv
      # lua tooling; lua-language-server and stylua come from mise
      lua5_4
      lua54Packages.luacheck # not a top-level attr; match lua5_4 above
      # build tools
      cmake
      meson
      automake
      libtool
      # formatters
      treefmt
      nixfmt
      # version manager; the tools it manages live in mise/config.toml
      unstable.mise
      # screenshot;
      unstable.flameshot
      # media
      ffmpeg
      imagemagick
      ghostscript
      tectonic
      # libs that were explicitly brew-installed (likely for local builds)
      hdf5
      c-blosc
      # brew openssh was probably for fido2/security-key support; macOS ships
      # its own ssh, and the nix one lacks keychain (UseKeychain) integration
      openssh
      # macos gui (replaces casks)
      unstable.aerospace # 26.05's 0.20.3 ignores after-startup-command; 0.21.x works
      sketchybar
      kitty
      wezterm
      ghostty-bin # ghostty on darwin ships as a prebuilt binary package
      vial-darwin # linux uses unstable.vial; darwin repacks the dmg, see pkgs/vial-darwin.nix
      unstable.discord
      unstable.telegram-desktop
      # editor
      emacs
    ]
    ++ lib.mapAttrsToList mkWebApp (import ./web-apps.nix);
}
