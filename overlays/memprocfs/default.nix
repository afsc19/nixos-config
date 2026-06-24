{ inputs, ... }:
final: prev:
let
  # Extract the upstream overlay so `leechcore`, etc are available
  dma = inputs.dmatools.overlays.default final prev;
in
dma
// {
  memprocfs =
    (dma.memprocfs.override {
      python3 = prev.python312;
    }).overrideAttrs
      (old: {
        # TODO GCC 15 temp fix
        NIX_CFLAGS_COMPILE =
          (old.NIX_CFLAGS_COMPILE or "")
          + " -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types";

      });
}
