# NixOS Flakes Configuration
A NixOS flake providing system configurations for my personal computers and servers.

This flake's structure is inspired by [diogotcorreia's NixOS dotfiles](https://github.com/diogotcorreia/dotfiles) and is organized into 8 primary directories:

 - `hosts`: Each host is defined in its own directory, automatically including all `.nix` files within it. This is where modules are enabled, profiles are imported, and per-host custom options are configured.
 - `modules`: Modules that can be enabled and configured via options.
 - `profiles`: Profiles don't have any options and are imported into each hosts' configuration. Unlike other NixOS configurations, profiles are meant to be a collection of modules, packages or both.
 - `lib`: Helper functions and attributes. This also contains the logic that define's this structure.
 - `packages`: Custom definitions of packages that are not available in nixpkgs, made available in pkgs.my.
 - `overlays`: Custom nixpkgs overlays. Each file in this directory is automatically applied to the package set.
 - `secrets`: Per-host encrypted secrets managed with [agenix](https://github.com/ryantm/agenix).
 - `config`: Static assets and configuration files imported into the systems (wallpapers, certificates, equalizer presets, etc).

### Highlights:
 - [Home Manager](https://github.com/nix-community/home-manager)
 - [Gnome](https://www.gnome.org/)
 - [Nebula VPN](https://github.com/slackhq/nebula)
 - [Distrobox](https://github.com/89luca89/distrobox) with pod pre-installation
 - [rclone](https://github.com/rclone/rclone) mount
 - [Easyeffects](https://github.com/wwmm/easyeffects) presets
 - Grub with secure boot
 - My personal collection of forensic tools
 - Aarch64-linux compatibility
  
## Machines:
Machines follow a specific naming convention based on the fictional solar system from [ASTRONEER](https://astroneer.fandom.com/wiki/Astroneer_Wiki). Stationary system (those with a static physical location) are named after planets and moons.

### Zen - Personal Laptop (x86_64-linux)
My daily driver for general use:
 - **Desktop**: GNOME with my personal flavor of themes, plugins, and GUI apps.
 - **Virtualization**: VMWare, KVM and Distroboxes with pods for CTFs.
 - **Boot**: Custom boot animation.
 - **Security**: Uses fido2 for secrets, and skips secure boot on GRUB (workaround for now - what an hypocrisy).
 - **Gaming**: Steam, Proton-GE, Hydra, Roblox - packed for procrastination.
 - **Discord**: Equicord via Nixcord - thanks [ang3lo-azevedo](https://github.com/ang3lo-azevedo).
 - **Restic**: Gotta keep in touch with my cloud storage.

### Sylva - Oracle VPS (aarch64-linux)
The public-facing primary server and lighthouse machine, chosen for it's high bandwidth:
 - **Nebula VPN**: The main lighthouse to assist me with NAT punching.
 - **Services**: Hosts my personal and private services.

*(Nothing else for now.)*

### Favilla - Stationary Laptop (x86_64-linux)
Named after Calidor's moon, this machine serves as Calidor's instancer and wakes occasionally to assist sylva with heavy workloads.
 - **Mr. Soldier** - Nothing for now, just part of the army.
<br><br>
#### Machines not yet deployed:
 - `calidor`: Stationary Desktop - Built to hoard data and handle GPU-intensive tasks.


## Deployment

### *(Recommended)* Manual installation - From live installer to flake
If you haven't already, boot into a NixOS live installer. <br>
I strongly recommend using a graphical installer to use GUI tools to assist the process.<br>
Use [netboot.xyz](https://github.com/netbootxyz/netboot.xyz) if you don't have access to a bootable USB/ISO, but have a network connection.
1. Establish a network connection.
2. Partition your storage if you haven't already. (Use GParted if on a graphical installer)
3. Mount the filesystem partition on `/mnt` and the boot partition on `/mnt/boot`. (Use GParted again or `sudo mount /dev/sdXY /mnt && sudo mount /dev/sdXZ /mnt/boot`, taking sdX as your storage device, Y as the number of the filesystem partition and Z as the number of the boot partition)
4. Make sure your system has an ssh key (Use `sudo ssh-keygen -t ed25519 -f /mnt/etc/ssh/ssh_host_ed25519_key`)
5. Add this ssh key to [secrets.nix](./secrets/secrets.nix) and rekey the secrets in another machine (commit and push).
6. Make sure you have git installed (or use  `nix-shell -p git`).
7. Clone this repository to a folder inside /mnt (such as /mnt/etc/\<nixos-config>).
8. Generate a hardware configuration using `nixos-generate-config --show-hardware-config` and add it as a `hardware.nix` to the dedicated host's folder.
9. Run `sudo nixos-install --root /mnt --flake .#<hostname>`.

### Manual installation - From a NixOS installation to flake
If you haven't already, install NixOS using [the dedicated graphical installer](https://nixos.org/download/) for ease.
1. Establish a network connection.
2. Make sure your system has an ssh key (use `sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key`)
3. Make sure you have git installed (or use  `nix-shell -p git`).
4. Clone this repository to a folder inside /mnt (such as /mnt/etc/\<nixos-config>).
5. Add this ssh key to [secrets.nix](./secrets/secrets.nix) and rekey the secrets in another machine (commit and push).
6. Generate a hardware configuration using `nixos-generate-config --show-hardware-config` and add it as a `hardware.nix` to the dedicated host's folder.
7. Run `sudo nixos-rebuild switch --flake .#<hostname>` on the configuration's root folder.

### Deploying through SSH (with secrets - [nixrnl](https://github.com/rnl-dei/nixrnl))
  > **Warning:** Do not use deploy-anywhere without setting up disko for that machine.

Start a shell with a development environment:
```bash
nix develop
```

And then run the following command to deploy a new machine:
```bash
deploy-anywhere .#<nixosConfiguration> root@<ip/hostname> [<sshHostKey>]
```
Description of the arguments:
- `<nixosConfiguration>`: The machine's hostname.
- `<ip/hostname>`: The IP address or hostname of the machine to deploy to.
- `<sshHostKey>` (Optional): The SSH host key of the machine to deploy to. This value should be the name of the secret in the `secrets/host-keys` directory (without the `.age`). If omitted, the VM cannot have secrets using Agenix and will generate a new SSH host key.

After the deployment is complete, you should be able to SSH into the machine.


### *(Recommended)* How to create a live USB/ISO?

To deploy your flake using a custom live USB/ISO, you need to either create a copy or temporarily add `installation-cd-graphical-calamares-gnome.nix` or [a similar installer](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/cd-dvd) to your host's configuration.

Also add this to the configuration, so the flake source is bundled:

```nix
isoImage.contents = [
  { source = ./.; target = "/nixos-config-source"; }
];
```

// # TODO Implement a declarative creation of '\<hostname>-live' config

> Warning: Regarding agenix secrets, you must use a fido2 key or create the machine's ssh host key in advance, rekey the secrets, and transfer the key pair alongside the live USB/ISO. (Place it in the flake's root directory so it's bundled altogether, or just use an extra USB)

To create an ISO from a host configuration, you should run the following command:
```bash
nix build .#nixosConfigurations.<nixosConfiguration>.config.system.build.isoImage
```

Description of the arguments:
- `<nixosConfiguration>`: The name of the configuration you edited or copied.

After the ISO is built, you can write it to a USB drive using the following command:
```bash
dd if=result/iso/<nixosConfiguration>.iso of=/dev/sdX status=progress
```

The installation is now identical to a [manual installation](#recommended-manual-installation---from-live-installer-to-flake):
1. Establish a network connection.
2. Partition your storage if you haven't already. (Use GParted if on a graphical installer)
3. Mount the filesystem partition on `/mnt` and the boot partition on `/mnt/boot`. (Use GParted again or `sudo mount /dev/sdXY /mnt && sudo mount /dev/sdXZ /mnt/boot`, taking sdX as your storage device, Y as the number of the filesystem partition and Z as the number of the boot partition)
4. Make sure you have your fido2, or transfered ssh key in `/mnt/etc/ssh/ssh_host_ed25519_key`.
5. Make sure you have git installed (or use  `nix-shell -p git`).
6. Generate a hardware configuration using and add it as a `hardware.nix` to the dedicated host's folder, using: `sudo nixos-generate-config --root /mnt --show-hardware-config > /nixos-config-source/hosts/<nixosConfiguration>/hardware.nix`.
7. Run `sudo nixos-install --root /mnt --flake .#<nixosConfiguration>`.


## Useful links
 - [NixOS Search](https://search.nixos.org)
 - [All Nix functions](https://teu5us.github.io/nix-lib.html)


## References
My configuration was heavily inspired by:
 - [diogotcorreia/dotfiles](https://github.com/diogotcorreia/dotfiles)

And it was also inspired by the following configurations:
 - [ang3lo-azevedo/dotfiles](https://github.com/ang3lo-azevedo/dotfiles)
 - [nomadics9/NixOS-Flake](https://github.com/nomadics9/NixOS-Flake)
 - [dnordstrom/dotfiles](https://github.com/dnordstrom/dotfiles)
 - [rnl-dei/nixrnl](https://github.com/rnl-dei/nixrnl)