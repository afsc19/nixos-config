{
  config,
  pkgs,
  ...
}:
{
  # Essential System packages
  environment.systemPackages = with pkgs; [
    # Basic
    vim
    zig
    wget
    killall
    neofetch
    git
    gh
    tmux



    # Archives
    zip
    unzip
    gzip
    gnutar
    xz
    p7zip


    # Utils
    ripgrep


    # Misc
    fastfetch
    file
    which
    tree
    #gnused
    #gnutar
    #gawk
    #zstd
    gnupg # TODO learn this

    # Networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    dogdns    # better `dig`
    ldns # replacement of `dig`, it provides the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # Monitoring tools
    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    

    # System call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files


    # System tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
    


    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor
    agenix
  ];
}