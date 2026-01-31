{
  config,
  inputs,
  lib,
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
    "${systemRoot}/etc/ssh/ssh_host_ed25519_key"
    "/etc/age/fido2-hmac-magic.txt"
  ];

  environment.etc."age/fido2-hmac-magic.txt".text = "AGE-PLUGIN-FIDO2-HMAC-1VE5KGMEJ945X6CTRM2TF76";

  environment.systemPackages = with pkgs; [
    age
    age-plugin-fido2-hmac
  ];
}
