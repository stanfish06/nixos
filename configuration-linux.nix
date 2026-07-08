# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.extra-substituters = [ "https://nix-community.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSeBc="
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.geist-mono
    nerd-fonts.victor-mono
    nerd-fonts.iosevka-term
    maple-mono.NF
    iosevka
    inter
    ibm-plex
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "Inter"
      "Noto Sans CJK SC"
      "Noto Sans"
    ];
    serif = [
      "IBM Plex Serif"
      "Noto Serif CJK SC"
      "Noto Serif"
    ];
    monospace = [
      "Iosevka"
      "Noto Sans Mono CJK SC"
    ];
  };
  # docker
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      bip = "172.30.0.1/24"; # Need to set this otherwise it collides with school's netauth gateway
    };
  };
  # steam
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = true;
  };
  # currently not working well: have weird pixels
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  # enable dynamic linkage for tools like uv
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    atk
    cairo
    cups
    dbus
    expat
    glib
    libgbm
    libgcc
    libxkbcommon
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    zlib
  ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # CVE-2026-31431 (Copy Fail): algif_aead blacklist lifted — both hosts confirmed on
  #   kernel 6.18.36 (>= 6.18.22 fix threshold) as of 2026-06-29; patch is active.
  # CVE-2026-43284 / CVE-2026-43500 (Dirty Frag): rxrpc (AFS) remains blacklisted.
  # CVE-2026-31635 (DirtyDecrypt, CVSS 7.5): rxrpc blacklist covers this (RXGK auth runs atop rxrpc).
  # CVE-2026-46300 (Fragnesia, CVSS 7.8): XFRM ESP-in-TCP priv-esc via skb_try_coalesce;
  #   esp4/esp6 kept for VPN — accepted risk; kernel patch released 2026-05-13.
  # esp4/esp6 (IPsec ESP) are intentionally kept enabled for VPN use.
  boot.extraModprobeConfig = ''
    install rxrpc /bin/false
  '';
  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.wifi.backend = "iwd"; # this is somehow needed for enterprise wifi
  # Set your time zone.
  time.timeZone = "America/New_York";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Vial keyboard access over hidraw (https://get.vial.today/manual/linux-udev.html)
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  programs.zsh.enable = true;

  programs.firefox.enable = true;

  users.users.stan = {
    isNormalUser = true;
    description = "stan";
    shell = pkgs.zsh;
    initialPassword = "123456";
    extraGroups = [
      "networkmanager"
      "docker"
      "wheel"
    ];
  };
  users.users.root = {
    initialPassword = "123456";
  };
  environment.systemPackages = with pkgs; [
    # basic tools
    new.git
    new.vim
    new.wget
    new.curl
    # build tools
    new.gcc
    new.gnumake
    new.cmake
    new.pkg-config
    new.autoconf
    new.automake
    new.libtool
    # others
    new.tmux
    unstable.neovim
    new.zsh
    new.alacritty
    new.nixfmt
    new.nixfmt-tree
  ];
  environment.variables.EDITOR = "nvim";

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.niri.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment? Do not touch this.
}
