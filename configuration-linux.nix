{
  pkgs,
  ...
}:

{
  imports = [ ./modules/miniflux-linux.nix ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSeBc="
    ];
    trusted-users = [ "@wheel" ];
  };
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
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      bip = "172.30.0.1/24"; # Need to set this otherwise it collides with school's netauth gateway
    };
  };
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    install rxrpc /bin/false
  '';
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.wifi.backend = "wpa_supplicant"; # this is needed for enterprise wifi
  services.resolved.enable = true;
  time.timeZone = "America/New_York";
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
  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
  };
  services.printing.enable = true;
  # sound: pipewire replaces pulseaudio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # Remote desktop over Tailscale
  services.tailscale = {
    enable = true;
    # --operator lets `stan` run tailscale (incl. Taildrop `file cp`) without sudo
    extraSetFlags = [
      "--ssh"
      "--operator=stan"
    ];
  };
  programs.wayvnc.enable = true;
  # 5900: wayvnc remote desktop; 2022: eternal-terminal (etserver)
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    5900
    2022
  ];

  # Resilient ssh
  services.eternal-terminal.enable = true;

  # Vial keyboard access over hidraw (https://get.vial.today/manual/linux-udev.html)
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  programs.zsh.enable = true;

  programs.firefox.enable = true;

  programs.mosh.enable = true; # resilient ssh connection

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
    new.eternal-terminal
    # xterm-ghostty terminfo so ssh/et from Ghostty resolves TERM
    ghostty.terminfo
    unstable.neovim
    unstable.emacs31
    ispell # emacs needs it
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
