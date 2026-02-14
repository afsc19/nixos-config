{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # For Impermanence
  #cfgPersist = config.modules.impermanence;
  #systemRoot = lib.optionalString cfgPersist.enable cfgPersist.persistDirectory;
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/age/fido2-hmac-magic.txt"
  ];

  environment.etc."age/fido2-hmac-magic.txt".text = "AGE-PLUGIN-FIDO2-HMAC-1VE5KGMEJ945X6CTRM2TF76";

  environment.systemPackages = with pkgs; [
    age
    age-plugin-fido2-hmac
    libfido2 # for udev rules
  ];

  # Hardware support for security keys
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.libfido2 ];

  # Ensure the fido2-hmac plugin is available during activation/decryption
  age.ageBin =
    let
      ageWrapped = pkgs.writeShellScriptBin "age" ''
        export PATH=${lib.makeBinPath [ pkgs.age-plugin-fido2-hmac ]}:$PATH
        exec ${pkgs.age}/bin/age "$@"
      '';
    in
    "${ageWrapped}/bin/age";
}
