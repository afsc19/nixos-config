# OpenSSH server configuration
{ lib, ... }:
let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHh9INLI4sUow/VZaBoZGwdlr3ZoYa8/j58ahzSK1LPE afsc@zen"
  ];
in
{
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    ports = [ lib.my.ports.ssh ];

    # Disable RSA host key
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  usr.openssh.authorizedKeys.keys = sshKeys;

  modules.services.nebula.firewall.inbound = [
    {
      port = lib.my.ports.ssh;
      proto = "tcp";
      group = "afsc";
    }
  ];
}