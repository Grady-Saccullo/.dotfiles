# ESPHome dashboard for building/flashing DIY sensors. No auth of its own,
# so loopback only, reached through the proxy.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "esphome";
  inherit config;
} (cfg: {
  services.esphome = {
    enable = true;
    address = "127.0.0.1";
    port = 6052;
  };

  homelab.proxy.services.esphome = lib.mkDefault "http://127.0.0.1:6052";
})
