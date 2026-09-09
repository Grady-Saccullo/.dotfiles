# Keep an unattended box healthy: the Intel TCO hardware watchdog reboots
# a hung host. Upgrades are deliberate: CI builds every push, `deploy` is
# run by hand on a schedule. No auto-upgrade from a moving flake on the
# box that is the house's DNS.
{
  utils,
  config,
  ...
}:
utils.mkHomelabModule {
  path = "maintenance";
  inherit config;
  default = true;
} (cfg: {
  boot.kernelModules = ["iTCO_wdt"];
  systemd.watchdog = {
    runtimeTime = "30s";
    rebootTime = "5m";
  };
})
