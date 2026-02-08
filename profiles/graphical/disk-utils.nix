# Disk utils
{
  inputs,
  pkgs,
  ...
}:
{
  home-manager.sharedModules = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # Requires flatpak
  hm.services.flatpak = {
    enable = true;
    packages = [
      "org.gnome.baobab" # Usage Disk Analyzer
    ];
  };
  
  environment.systemPackages = with pkgs; [
    gparted
  ];

}
