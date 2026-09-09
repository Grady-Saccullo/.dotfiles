# Generic x86 micro PC (Dell OptiPlex Micro / Lenovo Tiny / HP EliteDesk
# Mini class). UEFI + systemd-boot, single disk laid out by disko as btrfs
# subvolumes so /var/lib gets hourly snapshots (NixOS generations roll back
# the system; snapshots roll back the state).
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
    loader.systemd-boot.configurationLimit = 10;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sdhci_pci"];
    kernelModules = ["kvm-intel"];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
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
            type = "btrfs";
            extraArgs = ["-f"];
            # top level mounted for btrbk; VM images without copy-on-write
            postCreateHook = ''
              MNT=$(mktemp -d)
              mount "$device" "$MNT" -o subvol=/
              mkdir -p "$MNT/@vms"
              chattr +C "$MNT/@vms"
              umount "$MNT"
            '';
            subvolumes = {
              "/@" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@var-lib" = {
                mountpoint = "/var/lib";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@var-log" = {
                mountpoint = "/var/log";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/@vms" = {
                mountpoint = "/var/lib/vms";
                mountOptions = ["noatime"];
              };
              "/@snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
  };

  # the whole filesystem, for btrbk
  fileSystems."/mnt/btr_pool" = {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "btrfs";
    options = ["subvol=/" "noatime"];
  };

  # hourly snapshots of state, kept seven days
  security.sudo.enable = true;
  services.btrbk.instances.state = {
    onCalendar = "hourly";
    settings = {
      timestamp_format = "long";
      snapshot_preserve_min = "7d";
      snapshot_preserve = "no";
      volume."/mnt/btr_pool" = {
        snapshot_dir = "@snapshots";
        subvolume."@var-lib" = {};
      };
    };
  };
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = ["/"];
  };

  # Sonoff Zigbee 3.0 dongle (CP2102N): stable /dev/zigbee symlink; the VM
  # takes it by vendor/product id regardless.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
  '';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
