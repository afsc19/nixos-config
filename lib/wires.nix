{ ... }:
{
  uptimewire = {
    fleet = {
      "sylva" = {
        ip = "10.100.0.1";
        pubkey = "TODO add pubkey";
        endpoint = "world.sylva.andrecadete.com";
        isHub = true;
      };
      "favilla" = {
        ip = "10.100.0.2";
        pubkey = "TODO add pubkey";
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