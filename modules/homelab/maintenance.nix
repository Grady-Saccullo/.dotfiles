# Keep an unattended box healthy: hardware watchdog reboot on hangs and
# optional nightly upgrades straight from the flake on GitHub (safe once
# CI builds the configuration before it lands on main).
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "maintenance";
  inherit config;
  default = true;
  extraOptions = {
    autoUpgrade = {
      enable = lib.mkEnableOption "nightly nixos-rebuild from the remote flake";
      flake = lib.mkOption {
        type = lib.types.str;
        default = "github:grady-saccullo/.dotfiles";
      };
      allowReboot = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
} (cfg: {
  systemd.watchdog = {
    runtimeTime = "30s";
    rebootTime = "3m";
  };

  system.autoUpgrade = lib.mkIf cfg.autoUpgrade.enable {
    enable = true;
    inherit (cfg.autoUpgrade) flake allowReboot;
    flags = ["--refresh"];
    dates = "04:00";
    randomizedDelaySec = "30min";
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
  };
})
