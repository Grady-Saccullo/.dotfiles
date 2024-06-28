{...}: {
  imports = [
    ./nixos-vm.nix
  ];

  boot.initrd.availableKernelModules = [
    "achi"
    "nvme"
    "sr_mod"
    "uhci_hcd"
    "usbhid"
    "xhci_pci"
  ];

  services.xserver = {
    enable = true;
    xkb.layout = "us";
    dpi = 220;
  };

  services.desktopManager.plasma6.enable = true;
}
