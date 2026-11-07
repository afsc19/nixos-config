# Freebuff - free terminal coding agent by Codebuff (https://freebuff.com)
# The npm package is only a launcher that downloads this prebuilt Bun binary into
# ~/.config/manicode and self-updates it, so we fetch the release archive directly.
# Hashes come from `binaryChecksums` in https://registry.npmjs.org/freebuff/<version>.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
let
  sources = {
    x86_64-linux = {
      target = "linux-x64";
      hash = "sha256-Zy1mw0RPdGnMIbnIocLAbAlnbKj2oXcVaCgldaRFppU=";
    };
    aarch64-linux = {
      target = "linux-arm64";
      hash = "sha256-7XUqWJWKAaMXLuvdo7f6v/J9TcCZ6Uxdijptpdl2kqM=";
    };
  };
  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "freebuff: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "freebuff";
  version = "0.2.36";

  src = fetchurl {
    url = "https://codebuff.com/api/releases/download/${finalAttrs.version}/freebuff-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;
  # Bun single-file executables keep the bundled JS appended to the ELF; stripping destroys it
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # Keep tree-sitter.wasm next to the binary, where it looks for it
    install -Dm755 freebuff $out/libexec/freebuff/freebuff
    install -Dm644 tree-sitter.wasm $out/libexec/freebuff/tree-sitter.wasm
    mkdir -p $out/bin
    ln -s $out/libexec/freebuff/freebuff $out/bin/freebuff

    runHook postInstall
  '';

  meta = {
    description = "Free AI coding agent for the terminal, by Codebuff";
    homepage = "https://freebuff.com";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
    maintainers = [ ];
    mainProgram = "freebuff";
  };
})
