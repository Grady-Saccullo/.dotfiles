# Raspberry Pi 4 Model B (4 GB). Root on the NixOS SD image layout, which
# boots equally well when the same image is written to a USB SSD (the Pi 4
# EEPROM on this board already has BOOT_ORDER=0xf14: SD first, then USB).
#
# Image build:  nix build .#nixosConfigurations.hackerpi.config.system.build.images.sd-card
{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.nixos-hardware.nixosModules.raspberry-pi-4];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = ["noatime"];
  };

  # The old Debian root (Samsung 840 PRO, PARTUUID 51e877ea-02), mounted
  # read-only while state is migrated. Remove this block, then repurpose the
  # SSD, once the migration in docs/homelab.md is finished.
  fileSystems."/mnt/legacy" = {
    device = "/dev/disk/by-partuuid/51e877ea-02";
    fsType = "ext4";
    options = ["ro" "nofail" "noatime"];
  };

  # No Wi-Fi / Bluetooth on this box (matches the old config.txt overlays).
  hardware.enableRedistributableFirmware = true;
  networking.wireless.enable = false;
  hardware.bluetooth.enable = false;

  # Sonoff Zigbee 3.0 dongle shows up as /dev/ttyUSB0; give it a stable name
  # too, in addition to /dev/serial/by-id.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
  '';

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
