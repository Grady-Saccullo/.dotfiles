# Mosquitto broker. Authenticated (passwords via sops) and reachable on the
# LAN so ESPHome / Shelly / Tasmota devices in the new place can publish
# directly. Replaces the anonymous, loopback-only container.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "mqtt";
  inherit config;
  extraOptions = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 1883;
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
} (cfg: {
  sops.secrets."mqtt/hass".owner = "mosquitto";
  sops.secrets."mqtt/zigbee2mqtt".owner = "mosquitto";

  services.mosquitto = {
    enable = true;
    persistence = true;
    listeners = [
      {
        address = "0.0.0.0";
        port = cfg.port;
        settings.allow_anonymous = false;
        users = {
          hass = {
            acl = ["readwrite #"];
            passwordFile = config.sops.secrets."mqtt/hass".path;
          };
          zigbee2mqtt = {
            acl = ["readwrite #"];
            passwordFile = config.sops.secrets."mqtt/zigbee2mqtt".path;
          };
        };
      }
    ];
  };

  networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
})
