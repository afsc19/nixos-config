# IDA Pro
{
  pkgs,
  ...
}:
let
  idaRun = pkgs.requireFile {
    name = "ida-pro_93_x64linux.run";
    message = "xray";
    hash = "sha256-pk5lif7soPThv7li0aKDdh+zjFFY9fgsjx593zL2mFA="; 
  };
  scriptJs = pkgs.requireFile {
    name = "ida-pro_93_keygen.js";
    message = "xray";
    hash = "sha256-22lFBAtiV/Br2qG+XibsPol7RceDveqVINXKYrf1sAc=";
  };
  ida-chat-plugin = pkgs.fetchFromGitHub {
    owner = "HexRaysSA";
    repo = "ida-chat-plugin";
    rev = "HEAD";
    sha256 = "sha256-ueGelV0KZhE4k7O5VsBTSfZgWz/gm9Lr3CdIYl99Yd8=";
  };
in {
  hm.home.packages = with pkgs; [
    # IDA Pro
    (ida-pro.overrideAttrs (old: {
      version = "9.3.0";
      src = idaRun;

      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.nodejs ];
      buildInputs = (old.buildInputs or []) ++ [ pkgs.libxcrypt-legacy ];

      postInstall = (old.postInstall or "") + ''
        if [ -d "$out/opt" ]; then
          cp ${scriptJs} "$out/opt/script.js"
          cd "$out/opt"
          node ./script.js
        fi
      '';
    }))
    # (ida-chat-plugin.overrideAttrs (old: {
    #   buildInputs = (old.buildInputs or []) ++ [ cmake python311 ];
    #   nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ cmake python311 ];
    # }))
  ];
}
