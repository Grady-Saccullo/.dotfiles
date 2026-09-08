# Zigbee2MQTT with the Sonoff Zigbee 3.0 (CC2652P) coordinator. Settings are
# declarative; paired devices/groups persist in devices.yaml / groups.yaml
# and database.db under dataDir. The network key is read from a sops
# rendered secret.yaml, so carrying it over means no re-pairing.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "zigbee2mqtt";
  inherit config;
  extraOptions = {
    serialPort = lib.mkOption {
      type = lib.types.str;
      description = "Coordinator device, prefer a /dev/serial/by-id path.";
    };
    adapter = lib.mkOption {
      type = lib.types.str;
      default = "zstack";
    };
    channel = lib.mkOption {
      type = lib.types.int;
      default = 11;
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Expose the frontend directly instead of only via the proxy.";
    };
  };
} (cfg: let
  dataDir = "/var/lib/zigbee2mqtt";
  mqttPort = toString config.homelab.mqtt.port;
in {
  sops.secrets."zigbee2mqtt/network_key" = {};
  sops.secrets."zigbee2mqtt/auth_token" = {};
  sops.secrets."mqtt/zigbee2mqtt" = {};

  # Rendered next to configuration.yaml; values are referenced from the
  # settings below with the documented `'!secret.yaml <key>'` syntax.
  sops.templates."zigbee2mqtt-secret.yaml" = {
    path = "${dataDir}/secret.yaml";
    owner = "zigbee2mqtt";
    mode = "0400";
    restartUnits = ["zigbee2mqtt.service"];
    content = ''
      network_key: ${config.sops.placeholder."zigbee2mqtt/network_key"}
      mqtt_password: ${config.sops.placeholder."mqtt/zigbee2mqtt"}
      auth_token: ${config.sops.placeholder."zigbee2mqtt/auth_token"}
    '';
  };

  services.zigbee2mqtt = {
    enable = true;
    inherit dataDir;
    settings = {
      homeassistant.enabled = true;
      availability.enabled = true;
      frontend = {
        enabled = true;
        port = 8080;
        host =
          if cfg.openFirewall
          then "0.0.0.0"
          else "127.0.0.1";
        # the frontend can pair and control every device; never leave it open
        auth_token = "!secret.yaml auth_token";
        url = "https://zigbee.${config.homelab.domain}";
      };
      mqtt = {
        server = "mqtt://127.0.0.1:${mqttPort}";
        base_topic = "zigbee2mqtt";
        user = "zigbee2mqtt";
        password = "!secret.yaml mqtt_password";
      };
      serial = {
        port = cfg.serialPort;
        inherit (cfg) adapter;
      };
      advanced = {
        network_key = "!secret.yaml network_key";
        inherit (cfg) channel;
        log_level = "info";
        last_seen = "ISO_8601";
      };
    };
  };

  systemd.services.zigbee2mqtt.after = ["mosquitto.service"];
  homelab.proxy.services.zigbee = lib.mkDefault "http://127.0.0.1:8080";

  networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall 8080;
})
