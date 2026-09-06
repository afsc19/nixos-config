{ ... }:
_final: prev: {
  binary-ninja-personal-wayland = prev.binary-ninja-personal-wayland.overrideAttrs (old: {
    desktopIcon = prev.fetchurl {
      url = "https://docs.binary.ninja/img/logo.png";
      hash = "sha256-waXgwz9lSJ2zPahtqCP+ZdL5Ac6RZ4/pnz7iB4bTs4c=";
    };
  });
}
