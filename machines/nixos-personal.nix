{ user, machine-specific-imports }:
{ pkgs, ... }:
{
	nix = {
		extraOptions = ''
			experimental-features = nix-command flakes
		'';
	};

	users.users.${user} = {
		home = "/home/${user}";
		isNormalUser = true;
		extraGroups = [ "wheel" ];
		shell = pkgs.zsh;
	};

	programs.zsh.enable = true;

	boot.kernelPackages = pkgs.linuxPackages_latest;

	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	boot.loader.efi.efiSysMountPoint = "/boot";

	boot.initrd.availableKernelModules = [ "xhci_pci" "uhci_hcd" "virtio_pci" "usbhid" "usb_storage" "sr_mod" ];

	environment.shells = with pkgs; [ bashInteractive zsh ];

	fileSystems."/" = {
		device = "/dev/disk/by-partlabel/root";
	};
	fileSystems."/boot" = {
		device = "/dev/disk/by-partlabel/EFI";
	};

	services.xserver = {
		enable = true;
		xkb.layout = "us";
		dpi = 220;
	};

	services.desktopManager.plasma6.enable = true;
}
