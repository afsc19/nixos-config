{ inputs, ... }:
final: prev:
let
  # 1. Extract the upstream overlay so `leechcore` and friends are available
  dma = inputs.dmatools.overlays.default final prev;
in
dma
// {
  # 2. Patch memprocfs to strictly use Python 3.12
  memprocfs =
    (dma.memprocfs.override {
      python3 = prev.python312;
    }).overrideAttrs
      (old: {
        # TODO python 3.12 temporarily
        nativeBuildInputs = (prev.lib.remove prev.python3 (old.nativeBuildInputs or [ ])) ++ [
          prev.python312
        ];
        buildInputs = (prev.lib.remove prev.python3 (old.buildInputs or [ ])) ++ [ prev.python312 ];

        # TODO GCC 15 temp fix
        NIX_CFLAGS_COMPILE =
          (old.NIX_CFLAGS_COMPILE or "")
          + " -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types";

      });
}
