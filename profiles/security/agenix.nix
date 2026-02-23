{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  fido2 = config.my.security.fido2;
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  options.my.security.fido2 = {
    enable = lib.mkEnableOption "FIDO2 hardware security key support for agenix";
  };

  config = {
    age.identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ]
    ++ lib.optional fido2.enable "/etc/age/fido2-hmac-magic.txt";

    environment.etc."age/fido2-hmac-magic.txt" = lib.mkIf fido2.enable {
      text = "AGE-PLUGIN-FIDO2-HMAC-1VE5KGMEJ945X6CTRM2TF76";
    };

    environment.systemPackages =
      with pkgs;
      [
        age
      ]
      ++ lib.optionals fido2.enable [
        age-plugin-fido2-hmac
        libfido2 # for udev rules
      ];

    # Hardware support for security keys
    services.pcscd.enable = lib.mkIf fido2.enable true;
    services.udev.packages = lib.mkIf fido2.enable [ pkgs.libfido2 ];

    # Ensure the fido2-hmac plugin is available during activation/decryption
    age.ageBin = lib.mkIf fido2.enable (
      let
        ageWrapped = pkgs.writeShellScriptBin "age" ''
          export PATH=${lib.makeBinPath [ pkgs.age-plugin-fido2-hmac ]}:$PATH
          exec ${pkgs.age}/bin/age "$@"
        '';
      in
      "${ageWrapped}/bin/age"
    );
  };
}
