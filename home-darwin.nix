{ pkgs, ... }:
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # shell + cli
    atuin
    autossh
    bat
    btop
    chafa
    chezmoi
    clipboard-jh # brew calls this "clipboard"
    coreutils
    eza
    fd
    fzf
    jq
    mosh
    ripgrep
    television
    yazi
    zoxide
    # git
    gh
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
    # lua tooling
    lua5_4
    lua-language-server
    lua54Packages.luacheck # not a top-level attr; match lua5_4 above
    stylua
    # build tools
    cmake
    meson
    automake
    libtool
    shellcheck
    # formatters
    treefmt
    nixfmt
    # runtimes / version manager
    mise
    nodejs
    # media
    ffmpeg
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
    # editor
    emacs
  ];
}
