# KVM/libvirt configuration
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.virtualization.kvm;
in
{
  options.modules.virtualization.kvm.enable = mkEnableOption "KVM/libvirt";

  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };

    # Necessary for virt-manager to work
    programs.virt-manager.enable = true;

    # Add user to the libvirtd/kvm group
    usr.extraGroups = [ "libvirtd" "kvm" ];

    # Better spice support
    services.spice-vdagentd.enable = true;

    environment.systemPackages = with pkgs; [
      qemu
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
    ];
  };
}
