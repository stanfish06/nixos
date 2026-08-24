final: prev:
let
  version = "0.15.6.1";

  deps = with final; [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gcc-unwrapped.lib
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libkrb5
    libpulseaudio
    libva
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxshmfence
    libxtst
    nspr
    nss
    pango
    pipewire
    qt6.qtbase
    qt6.qtwayland
    systemd
    vulkan-loader
    wayland
  ];

  rpath = final.lib.makeLibraryPath deps + ":" + final.lib.makeSearchPathOutput "lib" "lib64" deps;
in
{
  helium = final.stdenvNoCC.mkDerivation {
    pname = "helium";
    inherit version;

    src = final.fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
      hash = "sha256-TVzi5ZWyvFsh6ovoBhU5DW0k3wlQ5/gUDD4+ykAQPTY=";
    };

    nativeBuildInputs = [
      final.makeWrapper
      final.patchelf
    ];

    # for XDG_ICON_DIRS and GSETTINGS_SCHEMAS_PATH, consumed in installPhase
    buildInputs = [
      final.adwaita-icon-theme
      final.glib
      final.gsettings-desktop-schemas
      final.gtk3
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/helium"
      cp -a . "$out/opt/helium"

      install -Dm444 helium.desktop "$out/share/applications/helium.desktop"
      install -Dm444 product_logo_256.png "$out/share/icons/hicolor/256x256/apps/helium.png"
      substituteInPlace "$out/share/applications/helium.desktop" \
        --replace-fail 'Exec=helium' "Exec=$out/bin/helium"

      # gl/va/pipewire/pulse are dlopened, so they need the library path rather
      # than the rpath below
      makeWrapper "$out/opt/helium/helium" "$out/bin/helium" \
        --prefix LD_LIBRARY_PATH : "${rpath}" \
        --suffix PATH            : "${final.lib.makeBinPath [ final.xdg-utils ]}" \
        --prefix XDG_DATA_DIRS   : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH:${final.addDriverRunpath.driverLink}/share" \
        --set CHROME_VERSION_EXTRA nix \
        --set CHROME_WRAPPER "$out/bin/helium" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

      for elf in helium helium_crashpad_handler chromedriver; do
        patchelf --set-interpreter ${final.bintools.dynamicLinker} --set-rpath "${rpath}" "$out/opt/helium/$elf"
      done
      for lib in libEGL.so libGLESv2.so libvk_swiftshader.so libvulkan.so.1 libqt6_shim.so; do
        patchelf --set-rpath "${rpath}" "$out/opt/helium/$lib"
      done

      runHook postInstall
    '';

    meta = {
      description = "Private, fast, and honest web browser based on Chromium";
      homepage = "https://helium.computer/";
      license = final.lib.licenses.gpl3Only;
      sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
      mainProgram = "helium";
      platforms = [ "x86_64-linux" ];
    };
  };
}
