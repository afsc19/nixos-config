{ ... }:
{
  # Keep a list of ports in a single file to make it easier to keep
  # track of assigned ports across all profiles/modules
  ports = {
    ssh = 22;
    dns = 53;
    http = 80;
    https = 443;

    mdnsGoogleCast = 5353;

    # Monitoring
    grafana = 3000;
    prometheusCrowdsec = 6060;
    komodoPeriphery = 8120;
    prometheusServer = 9090;
    cockpit = 9091;
    prometheusExporter = 9100;
    prometheusNginx = 9113;
    prometheusBlackbox = 9115;
    komodoCore = 9120;


    # A more reserved alternative to 8080
    nginxStubStatus = 18080;

    mc = 25565;

    # 51820 is wireguard's default, let's start at 30 to be sure
    wireguardUptimeWire = 51830;
  };
}
