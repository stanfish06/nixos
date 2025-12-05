{ config, pkgs, ... }: 

{
  home.stateVersion = "24.05";
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
  ];
}
