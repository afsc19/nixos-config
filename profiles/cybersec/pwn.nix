# Pwn utils
{
  pkgs,
  inputs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    gef # Enhanced gdb
    pwndbg

    # gadgets
    one_gadget
  ];

  hm.home.shellAliases = {
    gdb = "${pkgs.pwndbg}/bin/pwndbg";
  };
}
