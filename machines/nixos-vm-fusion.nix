{...}: {
  imports = [
    ./nixos-vm.nix
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sr_mod"
    "uhci_hcd"
    "usbhid"
    "xhci_pci"
  ];

  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  services.desktopManager.defaultSession = "plasma";
  services.desktopManager.sddm.enable = true;
  services.desktopManager.sddm.enableHidpi = true;
  services.desktopManager.sddm.theme = "breeze-dark";
  services.desktopManager.plasma6.enable = true;
}
