{inputs, ...}: let
  inherit (inputs) self;
in {
  imports = [
    self.nixosModules.sensible
    self.homeManagerModules.nixosModule
    self.applications
  ];

  applications = {
    github-cli.enable = true;
    podman.enable = true;
    neovim = {
      enable = true;
      docker.enable = true;
    };
  };

  boot.initrd.availableKernelModules = ["xhci_pci" "uhci_hcd" "virtio_pci" "usbhid" "usb_storage" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  swapDevices = [];
}
