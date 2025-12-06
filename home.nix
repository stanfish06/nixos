{ config, pkgs, ... }: 

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
  home.packages = with pkgs; [
    fzf
    ripgrep
    rofi
    dwl
    wmenu
    gh
  ];
}
