# Archi - ArchiMate modelling tool (https://github.com/archimatetool/archi)
# Follows the same Eclipse RCP repackaging pattern as nixpkgs' dbeaver-bin: drop the bundled JRE in favour of nixpkgs' JDK.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  glib,
  webkitgtk_4_1,
  glib-networking,
  openjdk21,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "archi";
  version = "5.10.0";
  tag = "5.10_0";

  src = fetchurl {
    url = "https://github.com/archimatetool/archi.io/releases/download/${finalAttrs.tag}/Archi-Linux64-${finalAttrs.version}.tgz";
    hash = "sha256-+UIkVaAKIvU0DcKGks6v4K1yDIzeg56q+w+rHOpXKH8=";
  };

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
    wrapGAppsHook3
    autoPatchelfHook
  ];

  buildInputs = [
    gtk3
    glib
    webkitgtk_4_1
    glib-networking
  ];

  dontConfigure = true;
  dontBuild = true;

  sourceRoot = ".";

  desktopItems = [
    (makeDesktopItem {
      name = "archi";
      desktopName = "Archi";
      comment = "ArchiMate modelling tool";
      exec = "archi";
      icon = "archi";
      categories = [
        "Graphics"
        "Education"
      ];
      startupWMClass = "Archi";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/archi $out/bin
    cp -r Archi/* $out/opt/archi/
    chmod +x $out/opt/archi/Archi

    # Use nixpkgs' JDK instead of the bundled Temurin JRE
    rm -rf $out/opt/archi/jre

    # Drop JNA natives for other architectures, only keep linux-x86-64.
    # Only removes subdirectories so the JNA class files are preserved.
    for jnaDir in $out/opt/archi/plugins/com.sun.jna_*/com/sun/jna; do
      if [ -d "$jnaDir" ]; then
        for entry in "$jnaDir"/*/; do
          case "$entry" in
            */linux-x86-64/) ;;
            */) rm -rf "$entry" ;;
          esac
        done
      fi
    done

    makeWrapper $out/opt/archi/Archi $out/bin/archi \
      --prefix PATH : "${lib.makeBinPath [ openjdk21 ]}" \
      --set JAVA_HOME "${openjdk21.home}" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          gtk3
          glib
          webkitgtk_4_1
          glib-networking
        ]
      }"

    install -Dm644 $out/opt/archi/icon.xpm $out/share/pixmaps/archi.xpm
    mkdir -p $out/share/icons/hicolor/48x48/apps
    ln -s $out/share/pixmaps/archi.xpm $out/share/icons/hicolor/48x48/apps/archi.xpm

    runHook postInstall
  '';

  meta = with lib; {
    description = "Free, open source, cross-platform tool to create ArchiMate models";
    homepage = "https://www.archimatetool.com";
    changelog = "https://www.archimatetool.com/version-history";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "archi";
  };
})
