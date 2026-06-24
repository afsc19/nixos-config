{ ... }:
_final: prev: {
  unblob = prev.unblob.overrideAttrs (_old: {
    doCheck = false;
    doInstallCheck = false;
  });
}
