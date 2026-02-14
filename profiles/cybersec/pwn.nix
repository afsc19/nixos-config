# Pwn utils
{
  hm,
  pkgs,
  inputs,
  ...
}:
let
  pwndbg = inputs.pwndbg.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  hm.home.packages = with pkgs.unstable; [
    gef # Enhanced gdb
    pwndbg
  ];

  hm.home.shellAliases = {
    gdb = "${pwndbg}/bin/pwndbg";
  };
}