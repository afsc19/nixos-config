# Sparx Systems Enterprise Architect (Wine).
# https://www.sparxsystems.com/enterprise_architect_user_guide/17.1/getting_started/enterprise_architect_linux.html
# in sum, on first run: wine prefix init, winetricks msxml3/msxml4/mdac28 (+jet40), the *msado15 native override, and `wine msiexec /i <msi>`.
# everything mutable lives in ~/.local/share/enterprise-architect.
{
  lib,
  writeShellApplication,
  wineWow64Packages,
  winetricks,
  icoutils,
  desktop-file-utils,
  curl,
  coreutils,
  findutils,
}:
writeShellApplication {
  name = "enterprise-architect";

  runtimeInputs = [
    wineWow64Packages.stable
    winetricks
    icoutils
    desktop-file-utils
    curl
    coreutils
    findutils
  ];

  # reviewed from an LLM
  text = ''
    set -euo pipefail

    DATA_DIR="''${ENTERPRISE_ARCHITECT_DATA_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/enterprise-architect}"
    PREFIX="$DATA_DIR/prefix"
    APPS_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    ICONS_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
    MSI="''${ENTERPRISE_ARCHITECT_MSI:-$HOME/Downloads/software/enterprise_architect/easetupfull_x64.msi}"
    MARKER="$DATA_DIR/.setup-done"
    EXE_FILE="$DATA_DIR/ea-exe-path"
    ADDONS_DIR="$DATA_DIR/addons"
    SETUP_VERSION="3"

    # Must match the Wine release in use (see dlls/appwiz.cpl/addons.c).
    MONO_VERSION="10.4.1"
    MONO_SHA="071f4b2887e1c97a11d791ff3d65be9429eed6dec4c2708888bfd546ba358e23"
    GECKO_VERSION="2.47.4"
    GECKO_SHA_X86="26cecc47706b091908f7f814bddb074c61beb8063318e9efc5a7f789857793d6"
    GECKO_SHA_X64="e590b7d988a32d6aa4cf1d8aa3aa3d33766fdd4cf4c89c2dcc2095ecb28d066f"

    export WINEPREFIX="$PREFIX"
    export WINEARCH=win64
    export WINEDEBUG="''${WINEDEBUG:-fixme-all}"

    die() {
      echo "enterprise-architect: $*" >&2
      exit 1
    }

    warn() {
      echo "enterprise-architect: warning: $*" >&2
    }

    usage() {
      cat <<'EOF'
    Usage: enterprise-architect [OPTION]... [EA-ARGS]...

    Launch Sparx Systems Enterprise Architect via Wine. The first run performs
    the one-time setup from Sparx's Linux guide into
    ~/.local/share/enterprise-architect (takes several minutes, downloads
    Windows components via winetricks).

    Options:
      --setup       (re-)run the setup steps without launching
      --reinstall   wipe the Wine prefix and run setup from scratch
      --help        show this message

    Environment:
      ENTERPRISE_ARCHITECT_MSI        installer (default:
                                      ~/Downloads/software/enterprise_architect/easetupfull_x64.msi)
      ENTERPRISE_ARCHITECT_DATA_DIR   prefix parent dir (default:
                                      ~/.local/share/enterprise-architect)

    Notes:
      - The registered (full) build asks for a license key on first launch.
      - To upgrade EA later: run `wine uninstaller`, remove the old version,
        then `enterprise-architect --setup` with the new MSI in place.
    EOF
    }

    apply_dll_overrides() {
      local reg
      reg="$(mktemp)"
      cat > "$reg" <<'EOF'
    REGEDIT4

    [HKEY_CURRENT_USER\Software\Wine\DllOverrides]
    "msado15"="native,builtin"
    "msxml3"="native,builtin"
    "msxml4"="native,builtin"
    EOF
      wine regedit "$reg"
      rm -f "$reg"
    }

    find_ea_exe() {
      find "$PREFIX/drive_c/Program Files/Sparx Systems" -maxdepth 3 -iname 'EA.exe' -print -quit 2>/dev/null || true
    }

    install_icon_and_desktop() {
      local exe="$1" tmp group groups png name best best_px px line
      tmp="$(mktemp -d)"
      mkdir -p "$tmp/pngs"
      # Collect RT_GROUP_ICON ids (the main application icon is group 128)
      # and extract the largest PNG across all of them.
      groups=()
      while IFS= read -r line; do
        if [[ "$line" == *"type=14 "* && "$line" =~ --name=([0-9]+) ]]; then
          groups+=("''${BASH_REMATCH[1]}")
        fi
      done < <(wrestool -l "$exe" 2>/dev/null || true)
      best=""
      best_px=0
      for group in "''${groups[@]}"; do
        if wrestool -x -t14 -n"$group" -o "$tmp/group.ico" "$exe" 2>/dev/null \
          && icotool -x -o "$tmp/pngs" "$tmp/group.ico" 2>/dev/null; then
          for png in "$tmp"/pngs/*.png; do
            [ -e "$png" ] || continue
            name="$(basename "$png")"
            if [[ "$name" =~ ([0-9]+)x([0-9]+)x[0-9]+ ]]; then
              px=$((BASH_REMATCH[1] * BASH_REMATCH[2]))
              if ((px > best_px)); then
                best_px="$px"
                best="$png"
              fi
            fi
          done
        fi
      done
      mkdir -p "$ICONS_DIR" "$APPS_DIR"
      if [ -n "$best" ]; then
        cp -f "$best" "$ICONS_DIR/enterprise-architect.png"
      else
        warn "could not extract an icon from EA.exe, launcher will use a fallback icon"
      fi
      rm -rf "$tmp"
      cat > "$APPS_DIR/enterprise-architect.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=Enterprise Architect
    Comment=Sparx Systems Enterprise Architect (running via Wine)
    Exec=enterprise-architect %F
    Icon=enterprise-architect
    Categories=Development;Office;
    StartupNotify=true
    StartupWMClass=ea.exe
    EOF
      update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
      if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "$(dirname "$(dirname "$ICONS_DIR")")" >/dev/null 2>&1 || true
      fi
    }

    current_wine_version() {
      wine --version 2>/dev/null || echo "unknown"
    }

    fetch_addon() {
      local url="$1" sha="$2" dest="$3" actual
      if [ -f "$dest" ]; then
        actual="$(sha256sum "$dest" | cut -d' ' -f1)"
        if [ "$actual" = "$sha" ]; then
          return 0
        fi
        warn "cached $(basename "$dest") failed checksum, re-downloading"
        rm -f "$dest"
      fi
      curl -fL --retry 3 -o "$dest" "$url" || die "failed to download $url"
      actual="$(sha256sum "$dest" | cut -d' ' -f1)"
      [ "$actual" = "$sha" ] || die "checksum mismatch for $(basename "$dest")"
    }

    # Install Wine Mono (.NET) and Gecko (embedded browser) up front so the
    # interactive download prompts never appear (they hang headless setups).
    install_addons() {
      local mono gecko_x86 gecko_x64
      mkdir -p "$ADDONS_DIR"
      mono="$ADDONS_DIR/wine-mono-$MONO_VERSION-x86.msi"
      gecko_x86="$ADDONS_DIR/wine-gecko-$GECKO_VERSION-x86.msi"
      gecko_x64="$ADDONS_DIR/wine-gecko-$GECKO_VERSION-x86_64.msi"
      fetch_addon "https://dl.winehq.org/wine/wine-mono/$MONO_VERSION/wine-mono-$MONO_VERSION-x86.msi" "$MONO_SHA" "$mono"
      fetch_addon "https://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine-gecko-$GECKO_VERSION-x86.msi" "$GECKO_SHA_X86" "$gecko_x86"
      fetch_addon "https://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine-gecko-$GECKO_VERSION-x86_64.msi" "$GECKO_SHA_X64" "$gecko_x64"
      wine msiexec /i "$mono" /qn
      wine msiexec /i "$gecko_x86" /qn
      wine msiexec /i "$gecko_x64" /qn
    }

    write_marker() {
      printf '%s %s\n' "$SETUP_VERSION" "$(current_wine_version)" > "$MARKER"
    }

    do_setup() {
      [ -f "$MSI" ] || die "installer not found: $MSI (set ENTERPRISE_ARCHITECT_MSI to override)"
      if [ "$(id -u)" = "0" ]; then
        warn "running as root is not recommended for Wine, continuing anyway"
      fi
      mkdir -p "$PREFIX"
      # Disabled during creation only: without Mono/Gecko present yet, the
      # boot would pop up interactive download dialogs and stall.
      WINEDLLOVERRIDES="mscoree=d;mshtml=d" wineboot --init
      install_addons
      winetricks -q msxml3 || die "msxml3 failed (Sparx note: you may need to place msxml.msi in ~/.cache/winetricks/msxml3)"
      winetricks -q --force msxml4 || warn "msxml4 reported errors, continuing (the DLL is usually still copied)"
      # Sparx: re-apply after Wine updates; is a no-op winetricks limitation on 64-bit prefixes.
      winetricks -q --force mdac28 || warn "mdac28 failed (expected on 64-bit prefixes), continuing"
      apply_dll_overrides
      # Optional: Jet 4.0 for Unicode .eap (Access) repositories.
      winetricks -q jet40 || warn "jet40 failed (expected on 64-bit prefixes), .eap Unicode support may be limited"
      wine msiexec /i "$MSI" /passive
      local exe
      exe="$(find_ea_exe)"
      [ -n "$exe" ] || die "EA.exe not found under $PREFIX after install"
      printf '%s' "$exe" > "$EXE_FILE"
      install_icon_and_desktop "$exe"
      write_marker
      echo "enterprise-architect: setup complete, launching..."
    }

    case "''${1:-}" in
      --help | -h)
        usage
        exit 0
        ;;
      --setup)
        do_setup
        exit 0
        ;;
      --reinstall)
        rm -rf "$PREFIX" "$MARKER" "$EXE_FILE"
        do_setup
        exit 0
        ;;
      --*)
        die "unknown option: $1 (see --help)"
        ;;
    esac

    if [ ! -f "$MARKER" ]; then
      do_setup
    elif [ "$(cut -d' ' -f2- "$MARKER")" != "$(current_wine_version)" ]; then
      # Sparx guidance: Wine updates can break mdac28, so re-apply it.
      warn "wine version changed since setup, re-applying mdac28"
      winetricks -q --force mdac28 || warn "mdac28 re-apply failed, continuing"
      apply_dll_overrides
      write_marker
    fi

    [ -f "$EXE_FILE" ] || die "setup marker exists but EA.exe path is unknown, run with --setup"
    wine "$(cat "$EXE_FILE")" "$@"
  '';

  meta = with lib; {
    description = "Sparx Systems Enterprise Architect 17 launcher (installs and runs the Windows build via Wine)";
    homepage = "https://sparxsystems.com/products/ea/";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "enterprise-architect";
  };
}
