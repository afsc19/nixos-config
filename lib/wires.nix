{ ... }:
{
  uptimewire = {
    fleet = {
      "zen" = {
        ip = "10.100.0.4";
        pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKot140Ud5EhIcbu4+qy4+OgMWlx+F4NlZ53QdXyFqo uptime@zen";
        isHub = false;
      };
      "sylva" = {
        ip = "10.100.0.1";
        pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEhFHgzZ4R/GIKUXEUYvpvbM7wQCZ4muZGFMzEzDBCeO uptime@sylva";
        endpoint = "world.sylva.andrecadete.com";
        isHub = true;
      };
      "favilla" = {
        ip = "10.100.0.2";
        pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKG6jTfqQk8px1Ub4EPrseqv8vbpIeypWJ0mZRGbyZu uptime@favilla";
        isHub = false;
      };
      "calidor" = {
        ip = "10.100.0.3";
        pubkey = "TODO add pubkey";
        isHub = false;
      };
    };
  };
}