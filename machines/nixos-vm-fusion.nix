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

  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.enableHidpi = true;
  services.displayManager.sddm.theme = "breeze-dark";
  services.desktopManager.plasma6.enable = true;
}
