{ config, pkgs, ... }: 

{
  home.stateVersion = "24.05";
  home.file.".config/nvim".source = pkgs.fetchFromGitHub {
    owner = "stanfish06";
    repo = "nvim";
    rev = "master";
    # sha256 = pkgs.lib.fakeSha256;
    sha256 = "sha256-dnS1hEq4Hw873BWVXDIF2rwtE9gP2pBYAY9UPdAnjEw=";
  };
}
