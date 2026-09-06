{ ... }:
_final: prev: let
  correctIcon = prev.fetchurl {
    url = "https://docs.binary.ninja/img/logo.png";
    hash = "sha256-waXgwz9lSJ2zPahtqCP+ZdL5Ac6RZ4/pnz7iB4bTs4c=";
  };
in {
  binary-ninja-personal-wayland = prev.binary-ninja-personal-wayland.overrideAttrs (old: {
    # TODO temp workaround
    # whole installPhase in order to avoid the incorrect icon's hash mismatch
    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/opt/binaryninja
      mkdir -p $out/share/pixmaps
      cp -r * $out/opt/binaryninja
      find $out/opt/binaryninja \
        -type f \
        -name '*.so' -or -name '*.so.*' \
        -not -name '*.bntl' \
        -not -name 'libbinaryninjacore.so.*' \
        -not -name 'libbinaryninjaui.so.*' \
        -not -name 'liblldb.so.*' \
        -not -name 'libshiboken6.abi*.so.*' \
        -not -name 'libpyside6.abi*.so.*' \
        -delete
      cp ${correctIcon} $out/share/pixmaps/binaryninja.png
      chmod +x $out/opt/binaryninja/binaryninja
      buildPythonPath "$pythonDeps"
      makeWrapper $out/opt/binaryninja/binaryninja $out/bin/binaryninja \
        --prefix PYTHONPATH : "$program_PYTHONPATH" \
        "''${qtWrapperArgs[@]}"

      runHook postInstall
    '';
  });
}
