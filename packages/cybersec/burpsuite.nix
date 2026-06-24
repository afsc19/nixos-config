{
  lib,
  stdenvNoCC,
  unzip,
  jdk,
  coreutils,
  systemd,
  libxcrypt-legacy,
}:

let
  releasesJson = builtins.fromJSON (
    builtins.readFile (
      builtins.fetchurl {
        url = "https://portswigger.net/burp/releases/data";
      }
    )
  );

  isStableDesktop = r: r.buildCategory == "desktop" && builtins.elem "Stable" r.releaseChannels;

  latestRelease = builtins.head (builtins.filter isStableDesktop releasesJson.ResultSet.Results);

  jarBuild = builtins.head (
    builtins.filter (b: b.BuildCategoryPlatform == "Jar") latestRelease.builds
  );

  version = jarBuild.Version;

  burpsuiteJar = builtins.fetchurl {
    url = "https://portswigger.net/burp/releases/download?product=desktop&version=${version}&type=Jar";
    sha256 = jarBuild.Sha256Checksum;
    name = "burpsuite-${version}.jar";
  };
in
stdenvNoCC.mkDerivation {
  pname = "burpsuite";
  inherit version;

  dontUnpack = true;

  installPhase = ''
        mkdir -p $out/share/burpsuite $out/share/applications $out/share/icons/hicolor/64x64/apps $out/bin

        cp "${burpsuiteJar}" $out/share/burpsuite/burpsuite_${version}.jar
        cp "$src/BurpLoaderKeygen.jar" $out/share/burpsuite/
        cp "$src/.config.ini" $out/share/burpsuite/

        ${unzip}/bin/unzip -p "${burpsuiteJar}" "resources/Media/icon64pro.png" > "$out/share/icons/hicolor/64x64/apps/burpsuite.png" 2>/dev/null || \
        ${unzip}/bin/unzip -p "${burpsuiteJar}" "resources/Media/icon64community.png" > "$out/share/icons/hicolor/64x64/apps/burpsuite.png" 2>/dev/null || true

        cat > "$out/share/applications/burpsuite.desktop" <<'DESKTOP'
    [Desktop Entry]
    Name=Burp Suite
    Exec=burpsuite
    Icon=burpsuite
    Type=Application
    Categories=Development;Security;
    Comment=Web Application Security Testing Suite
    StartupWMClass=BurpSuite
    DESKTOP

        cat > "$out/bin/burpsuite" <<'SCRIPT'
    #!/bin/sh
    set -e

    if [ -n "''$LD_LIBRARY_PATH" ]; then
      export LD_LIBRARY_PATH="NIX_LIBS:''$LD_LIBRARY_PATH"
    else
      export LD_LIBRARY_PATH="NIX_LIBS"
    fi

    if [ -n "''$PATH" ]; then
      export PATH="NIX_CORETOOLS:''$PATH"
    else
      export PATH="NIX_CORETOOLS"
    fi

    if [ -z "''$XDG_CONFIG_HOME" ]; then
      CONFIG_DIR="''$HOME/.config/burpsuite"
    else
      CONFIG_DIR="''$XDG_CONFIG_HOME/burpsuite"
    fi
    mkdir -p "''$CONFIG_DIR"
    if [ ! -f "''$CONFIG_DIR/config.ini" ]; then
      cp NIX_OUT/share/burpsuite/.config.ini "''$CONFIG_DIR/config.ini"
    fi

    if [ -z "''$TMPDIR" ]; then
      TMPDIR="''$HOME/.config"
    fi
    WORK_DIR="''$TMPDIR/burpsuite-''$$"
    rm -rf "''$WORK_DIR"
    mkdir -p "''$WORK_DIR"
    trap "rm -rf ''$WORK_DIR" EXIT

    ln -sf NIX_OUT/share/burpsuite/BurpLoaderKeygen.jar "''$WORK_DIR/"
    for jar in NIX_OUT/share/burpsuite/burpsuite*.jar; do
      ln -sf "''$jar" "''$WORK_DIR/"
    done
    ln -sf "''$CONFIG_DIR/config.ini" "''$WORK_DIR/.config.ini"

    cd "''$WORK_DIR"
    exec NIX_JAVA/bin/java -jar BurpLoaderKeygen.jar "''$@"
    SCRIPT

        sed -i \
          -e "s|NIX_LIBS|${
            lib.makeLibraryPath [
              (lib.getLib systemd)
              libxcrypt-legacy
            ]
          }|" \
          -e "s|NIX_CORETOOLS|${coreutils}/bin|" \
          -e "s|NIX_JAVA|${jdk}|" \
          -e "s|NIX_OUT|$out|" \
          "$out/bin/burpsuite"
        chmod +x "$out/bin/burpsuite"
  '';

  meta = with lib; {
    description = "Burp Suite web application security testing platform";
    platforms = platforms.linux;
    mainProgram = "burpsuite";
  };
}
