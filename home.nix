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
  home.packages = with pkgs; [
    fzf
    ripgrep
    rofi
    dwl
    wmenu
    gh
  ];
}
