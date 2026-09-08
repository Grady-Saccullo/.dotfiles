# Baseline for every NixOS host: nix settings, the primary user, SSH, and
# a few server-sensible defaults. Mirrors modules/darwin/sensible.nix.
{
  pkgs,
  lib,
  config,
  me,
  inputs,
  hosts,
  hostName,
  ...
}: let
  inherit (inputs) self;
  keys = import ../../hosts/keys.nix;
  otherHosts = lib.filterAttrs (n: h: n != hostName && h.sshHostKey != null) hosts;
in {
  assertions = [
    {
      assertion = keys.admin != [];
      message = "hosts/keys.nix: add at least one admin ssh public key (password auth is disabled)";
    }
  ];

  imports = [../shared/nix.nix];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
    settings = {
      # Let `nixos-rebuild --target-host` from the Mac push closures without
      # them being rejected as unsigned.
      trusted-users = [me.user];
    };
  };

  users.users.${me.user} = {
    isNormalUser = true;
    extraGroups = ["wheel" "dialout"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = keys.admin;
  };

  # Every other host in hosts/default.nix is pre-trusted.
  programs.ssh.knownHosts =
    lib.mapAttrs (name: h: {
      hostNames = [name "${name}.${config.homelab.domain}" h.address];
      publicKey = h.sshHostKey;
    })
    otherHosts;
  # Single-admin homelab: passwordless sudo so remote `nixos-rebuild --sudo`
  # deploys don't hang waiting on a tty. Flip to true if the box ever gets a
  # second user.
  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;
  environment.shells = with pkgs; [bashInteractive zsh];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.enable = true;

  # Every host exports node metrics; the monitoring role scrapes them all.
  services.prometheus.exporters.node = {
    enable = lib.mkDefault true;
    listenAddress = lib.mkDefault config.homelab.lan.address;
    port = 9100;
    enabledCollectors = ["systemd"];
  };
  networking.firewall.allowedTCPPorts = [9100];

  zramSwap.enable = true;
  services.smartd.enable = lib.mkDefault true;
  services.fstrim.enable = true;
  boot.tmp.cleanOnBoot = true;
  services.journald.extraConfig = "SystemMaxUse=500M";

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    usbutils
    pciutils
    lsof
  ];

  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = self.constants.stateVersion;
}
