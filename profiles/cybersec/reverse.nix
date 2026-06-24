# Tools for reverse engineering
{
  pkgs,
  profiles,
  ...
}:
let
  idaRun = ./ida93sp2/ida-pro_93_x64linux.run;
  scriptJs = ./ida93sp2/kg_patch/keygen.js;
  ida-chat-plugin = pkgs.fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-chat-plugin";
    rev = "HEAD";
    sha256 = "sha256-ueGelV0KZhE4k7O5VsBTSfZgWz/gm9Lr3CdIYl99Yd8=";
  };
in
{
  hm.home.packages = with pkgs; [
    ghidra
    jadx
  ];

  imports = with profiles.cybersec.rev; [
    angr
    binary-ninja
    ida
  ];
}
