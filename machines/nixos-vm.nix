{
  pkgs,
  systemConfig,
  ...
}: {
  system.statVersion = "24.05";

  nix = {
    package = pkgs.nixVersion.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  users.users.${systemConfig.user} = {
    home = "/home/${systemConfig.user}";
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = ["xhci_pci" "uhci_hcd" "virtio_pci" "usbhid" "usb_storage" "sr_mod"];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/root";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/EFI";
  };

  environment.shells = with pkgs; [bashInteractive zsh];

  services.sudo.wheelNeedsPassword = false;
}
