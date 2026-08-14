# Vial keyboard configurator for macOS.
#
# nixpkgs' `vial` is the linux AppImage (meta.platforms = x86_64-linux only), so
# the darwin host repackages the upstream .dmg instead. The homebrew cask is not
# used: it is deprecated and disabled from 2026-09-01 because the app fails the
# Gatekeeper check -- upstream ships it completely unsigned. Installing through
# nix sidesteps that, since the store copy never gets a com.apple.quarantine
# xattr and unsigned x86_64 code is still allowed under Rosetta.
#
# The .dmg is x86_64-only, so Rosetta 2 must be installed:
#   softwareupdate --install-rosetta --agree-to-license
#
# Bumping: set `version` to the new upstream tag without its leading "v" and
# refresh `hash` (set it to lib.fakeHash, build, copy the hash nix reports as
# "got:").
final: prev:
let
  version = "0.7.5";
in
{
  vial-darwin = final.stdenvNoCC.mkDerivation {
    pname = "vial";
    inherit version;

    src = final.fetchurl {
      url = "https://github.com/vial-kb/vial-gui/releases/download/v${version}/Vial-v${version}.dmg";
      hash = "sha256-tijbEfjfAS+q/M7vfes2tUghtQfUyXAzb4WlbIAOiHY=";
    };

    # the dmg is APFS, which undmg cannot read; 7zz can, and -snld keeps the
    # three relative symlinks pyinstaller puts in Contents/MacOS (base_library,
    # certifi, PyQt5 translations) that it otherwise drops as "dangerous"
    nativeBuildInputs = [ final._7zz ];

    unpackPhase = ''
      runHook preUnpack
      7zz x -snld "$src"
      runHook postUnpack
    '';

    sourceRoot = "Vial.app";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications/Vial.app" "$out/bin"
      cp -R . "$out/Applications/Vial.app"
      ln -s "$out/Applications/Vial.app/Contents/MacOS/Vial" "$out/bin/vial"
      runHook postInstall
    '';

    meta = {
      description = "Configurator of compatible keyboards in real time";
      homepage = "https://get.vial.today/";
      license = final.lib.licenses.gpl2Plus;
      sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
      mainProgram = "vial";
      platforms = final.lib.platforms.darwin;
    };
  };
}
