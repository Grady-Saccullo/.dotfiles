# Generic x86 micro PC (Dell OptiPlex Micro / Lenovo Tiny / HP EliteDesk
# Mini class). UEFI + systemd-boot, single disk laid out by disko.
#
# Fill in `device` with the stable /dev/disk/by-id/... path of the boot disk
# before running `nix run .#install homelab root@<ip>`; nixos-anywhere
# WIPES that disk.
{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.disko.nixosModules.disko];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sdhci_pci"];
    kernelModules = ["kvm-intel"];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    # Intel iGPU: only needed for hardware transcoding on a media box, but
    # harmless here and lets the same file be reused.
    graphics = {
      enable = true;
      extraPackages = [];
    };
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/TODO-boot-disk"; # `ls -l /dev/disk/by-id` on the installer
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };

  # Sonoff Zigbee 3.0 dongle (CP2102N): stable /dev/zigbee symlink in
  # addition to /dev/serial/by-id.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
