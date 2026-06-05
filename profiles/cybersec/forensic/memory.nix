# Windows utils
{
  pkgs,
  ...
}:
{
  hm.home.packages = with pkgs; [
    volatility3
    volatility2-bin
    my.cybersec.volatility-toolkit
    # my.cybersec.evolve # web interface for volatility

    # mount a filesystem to analyze windows memory dumps
    memprocfs
    bulk_extractor

  ];
}
