# Home Assistant, natively packaged. Recorder on PostgreSQL over a unix
# socket (peer auth, no password), go2rtc for camera streams, adaptive
# lighting from nixpkgs. Replaces the container + MariaDB + InfluxDB +
# ring-mqtt: long-term history uses HA's built-in statistics, cameras use
# the core `ring` integration.
#
# configuration.yaml is owned by Nix. Automations, scripts and scenes stay
# UI-editable through the `!include` files in /var/lib/hass.
{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkHomelabModule {
  path = "home-assistant";
  inherit config;
  extraOptions = {
    homekitPort = lib.mkOption {
      type = lib.types.port;
      default = 21063;
      description = "Port the HomeKit bridge integration is configured to use.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Expose :8123 directly (the proxy is the intended path).";
    };
    extraComponents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };
} (cfg: let
  domain = config.homelab.domain;
in {
  ###########################################################################
  # Recorder database
  ###########################################################################
  services.postgresql = {
    enable = true;
    ensureDatabases = ["hass"];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };

  ###########################################################################
  # Camera streaming backend (Ring, Sonos, webOS, ...)
  ###########################################################################
  services.go2rtc = {
    enable = true;
    settings = {
      api.listen = "127.0.0.1:1984";
      rtsp.listen = "127.0.0.1:8554";
      webrtc.listen = ":8555";
    };
  };

  ###########################################################################
  # Home Assistant
  ###########################################################################
  services.home-assistant = {
    enable = true;
    openFirewall = cfg.openFirewall;

    extraComponents =
      [
        # integrations that exist as config entries today
        "apple_tv"
        "dlna_dmr"
        "go2rtc"
        "homekit"
        "ipp"
        "mobile_app"
        "mqtt"
        "sonos"
        "spotify"
        "thread"
        "webostv"
        # replacements / new-home additions
        "ring" # replaces ring-mqtt
        "matter" # services.matter-server (matter.nix)
        "esphome"
        # perf
        "isal"
        "zeroconf"
      ]
      ++ cfg.extraComponents;

    extraPackages = ps:
      with ps; [
        psycopg2 # recorder on PostgreSQL
      ];

    customComponents = [
      pkgs.home-assistant-custom-components.adaptive_lighting
    ];

    config = {
      default_config = {};

      homeassistant = {
        internal_url = "https://ha.${domain}";
        time_zone = config.time.timeZone;
      };

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
      };

      recorder = {
        db_url = "postgresql://@/hass";
        purge_keep_days = 14;
      };

      go2rtc.url = "http://127.0.0.1:1984";

      "automation ui" = "!include automations.yaml";
      "script ui" = "!include scripts.yaml";
      "scene ui" = "!include scenes.yaml";

      tts = [{platform = "google_translate";}];

      logger.default = "warning";
    };
  };

  systemd.services.home-assistant = {
    after = ["postgresql.service" "mosquitto.service" "go2rtc.service"];
    wants = ["postgresql.service"];
  };

  networking.firewall = {
    allowedTCPPorts = [cfg.homekitPort];
    allowedUDPPorts = [5353]; # mDNS: HomeKit, Sonos, Apple TV, Matter
  };
})
