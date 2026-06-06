{ ... }:
final: prev: {
  unblob = prev.unblob.overrideAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
  });
}