{
  description = "This Nix overlay fixes Dolphin's \"Open with\" menu when running outside of KDE (e.g., under Hyprland or other Wayland compositors)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { ... }: {
    overlays = {
      default = import ./default.nix;
    };
  };
}
