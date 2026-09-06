# By ang3lo-azevedo
{
  pkgs,
  config,
  ...
}:
let
  # Add the zip to your nix store and copy its hash:
  # nix hash file myzip.zip
  # nix-store --add-fixed sha256 myzip.zip
  # inherit
  # basePath = "/home/${user}/Downloads/software/binja";
  basePath = "${config.my.softwareDirectory}/binja";
  binjaZip = /. + "${basePath}/binaryninja_linux_stable_personal.zip";
  kgPath = /. + "${basePath}/keygen.py";
  correctIcon = pkgs.fetchurl {
    url = "https://docs.binary.ninja/img/logo.png";
    hash = "sha256-waXgwz9lSJ2zPahtqCP+ZdL5Ac6RZ4/pnz7iB4bTs4c=";
  };
in
{
  assertions = [
    {
      assertion = builtins.pathExists binjaZip && builtins.pathExists kgPath;
      message = "Binary Ninja files missing! Please place them in ${binjaZip} and ${kgPath}";
    }
  ];

  hm.home.file.".binaryninja/settings.json".text = builtins.toJSON {
    "python.binaryOverride" = "${pkgs.python312}/bin/python3.12";
    "python.interpreter" = "${pkgs.python312}/lib/libpython3.12.so";
  };

  programs.binary-ninja = {
    enable = true;
    package =
      (pkgs.binary-ninja-personal-wayland.override {
        overrideSource = binjaZip;
        python3 = pkgs.python312;

      }).overrideAttrs
        (old: {

          autoPatchelfIgnoreMissingDeps = [
            "libQt6WaylandEglClientHwIntegration.so.6"
          ];

          # FIXME temp workaround for logo hash mismatch
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

          # Use Python 3.12 for Sidekick plugin compatibility (requires 3.10-3.12)
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
            pkgs.python312Packages.pycryptodome
            pkgs.makeWrapper
          ];

          postInstall =
            (old.postInstall or "")
            + (
              if builtins.pathExists kgPath then
                ''
                  # Binary Ninja typically installs into $out/opt/binaryninja
                  if [ -d "$out/opt/binaryninja" ]; then
                    cp ${kgPath} "$out/opt/binaryninja/script.py"
                    cd "$out/opt/binaryninja"
                    ${pkgs.python312}/bin/python3 ./script.py
                  fi
                ''
              else
                ""
            );

          postFixup = (old.postFixup or "") + ''
            # Wrap the main binary to use Python 3.12 at runtime
            if [ -f "$out/bin/binaryninja" ]; then
              wrapProgram "$out/bin/binaryninja" \
                --set-default PYTHON ${pkgs.python312}/bin/python3 \
                --prefix PATH : ${pkgs.python312}/bin 
            fi
          '';
        });
  };
}
