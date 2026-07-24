{ pkgs, ... }:
{
  # home-manager configuration for the macbook (draft).
  #
  # This intentionally does not import home.nix: that file mixes portable
  # config with linux-only packages (wayland tools, rofi, dolphin, ...).
  # The long-term plan is to split home.nix into home-common.nix +
  # home-linux.nix + home-darwin.nix and import the common part here, which
  # brings the programs.* blocks (zsh, starship, atuin, mise, ...) along.
  # Dotfiles keep coming from chezmoi / ~/.config/dots for now; port the
  # mkOutOfStoreSymlink entries from home.nix when ready. Note home-manager
  # generating ~/.zshrc etc. will conflict with chezmoi-managed copies
  # (existing files get backed up with the .hm-bak suffix).

  home.stateVersion = "26.05";

  # replaces the explicitly installed brew formulas (brew leaves) and the
  # gui casks that exist in nixpkgs. brew-only dependencies (libpng,
  # icu4c, ...) disappear once the formulas that pulled them in are
  # uninstalled. gui apps land in ~/Applications/Home Manager Apps.
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
    luacheck
    stylua
    # build tools
    cmake
    meson
    automake
    libtool
    shellcheck
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
    aerospace
    sketchybar
    kitty
    wezterm
    ghostty-bin # ghostty on darwin ships as a prebuilt binary package
  ];
}
