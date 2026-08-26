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
in
{
  home.stateVersion = "26.05";

  xdg.configFile."mise/config.toml" = {
    source = "${inputs.my-configs}/mise/config.toml";
  };

  home.activation.initializeDeskflowSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir=${lib.escapeShellArg "${config.home.homeDirectory}/Library/Deskflow"}
    if [ ! -e "$settings_dir/Deskflow.conf" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$settings_dir"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 ${initialDeskflowSettings} "$settings_dir/Deskflow.conf"
    fi
  '';

  home.packages = with pkgs; [
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
    # zsh plugins; wire into .zshrc from the nix store paths, or port
    # programs.zsh from home.nix later
    zsh-autosuggestions
    zsh-syntax-highlighting
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
    mise
    # screenshot
    flameshot
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
    # editor
    emacs
  ];
}
