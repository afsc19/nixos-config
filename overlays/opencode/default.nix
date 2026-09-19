# FIXME temp fix
{ ... }:
final: prev: {
  opencode =
    let
      version = "1.18.31";

      src = prev.fetchurl {
        url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-${
          if prev.stdenv.hostPlatform.isx86_64 then "x64" else "arm64"
        }.tar.gz";
        sha256 =
          if prev.stdenv.hostPlatform.isx86_64 then
            "e9312be75ed803b7415fc2aeabda1f4fe938912a39673762dc0c38c0e11ebde4"
          else
            "d4e332f46b227448582c0d9fc75f6f826dfe95c9f751bc2011fc4d937a042be6";
      };

      unwrapped = prev.stdenv.mkDerivation {
        pname = "opencode-unwrapped";
        inherit version src;

        sourceRoot = ".";
        dontBuild = true;
        dontFixup = true; # patchelf/strip messes the bin

        # copy pasted
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp opencode $out/bin/.opencode-unwrapped
          chmod +x $out/bin/.opencode-unwrapped
          runHook postInstall
        '';
      };
    in
    prev.buildFHSEnv {
      # copy pasted
      name = "opencode";
      targetPkgs = pkgs: [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
      ];
      runScript = "${unwrapped}/bin/.opencode-unwrapped";
      meta = with prev.lib; {
        description = "AI coding agent built for the terminal";
        mainProgram = "opencode";
      };
    };

  # im using unstable
  unstable = prev.unstable // {
    inherit (final) opencode;
  };
}