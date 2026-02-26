{ ... }:
{
  # Keep a list of ports in a single file to make it easier to keep
  # track of assigned ports across all profiles/modules
  ports = {
    ssh = 22;
    http = 80;
    https = 443;

    mdnsGoogleCast = 5353;

    # Monitoring
    grafana = 3000;
    prometheusServer = 9090;
    prometheusExporter = 9100;

    # 51820 is default, let's start at 30 to be sure
    wireguardUptimeWire = 51830;
  };
}
