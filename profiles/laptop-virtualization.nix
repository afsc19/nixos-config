# Virtualization profile for laptop devices (docker+distrobox+vmware+kvm)
{
  pkgs,
  ...
}:
{

  modules.virtualization = {
    docker.enable = true;
    distrobox.enable = true;
    kvm.enable = true; # qemu_kvm + libvirtd
    vmware.enable = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
  ];
}
