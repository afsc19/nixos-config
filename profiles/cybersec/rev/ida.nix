# IDA Pro
{
  pkgs,
  config,
  ...
}:
let
  basePath = "${config.my.softwareDirectory}/ida93sp2";
  idaRun = /. + "${basePath}/ida-pro_93_x64linux.run";
  scriptJs = /. + "${basePath}/kg_patch/ida-pro_93_keygen.js";
in
{

  assertions = [
    {
      assertion = builtins.pathExists idaRun && builtins.pathExists scriptJs;
      message = "IDA files missing! Please place them in ${idaRun} and ${scriptJs}";
    }
  ];
  hm.home.packages = with pkgs; [
    # IDA Pro
    (ida-pro.overrideAttrs (old: {
      version = "9.3.0";
      src = idaRun;

      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.nodejs ];
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libxcrypt-legacy ];

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
