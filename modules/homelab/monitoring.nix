# Prometheus + Alertmanager + Grafana for the numbers, Gatus for "is it
# up" checks with ntfy alerts, a five-minute heartbeat to healthchecks.io
# as the dead-man's switch that lives outside the house, and Homepage as
# the household landing page listing every proxied service.
{
  utils,
  config,
  lib,
  pkgs,
  hosts,
  ...
}:
utils.mkHomelabModule {
  path = "monitoring";
  inherit config;
  extraOptions = {
    unifi = {
      enable = lib.mkEnableOption "unpoller metrics from the UniFi console";
      url = lib.mkOption {
        type = lib.types.str;
        default = "https://192.168.1.1";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "unpoller";
      };
    };
  };
} (cfg: let
  inherit (config.homelab) domain lan;
  nodeTargets = lib.mapAttrsToList (_: h: "${h.address}:9100") hosts;
  hassAddress =
    if config.homelab.hass.enable
    then config.homelab.hass.address
    else null;
in {
  sops.secrets."grafana/admin_password".owner = "grafana";
  sops.secrets."healthchecks/heartbeat_uuid" = {};
  sops.secrets."gatus/env" = {}; # NTFY_TOKEN=...
  sops.secrets."ntfy/token".owner = "alertmanager";

  ###########################################################################
  # Dead-man's switch: if this stops arriving, healthchecks.io pages you.
  ###########################################################################
  systemd.services.heartbeat = {
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 2 "https://hc-ping.com/$(cat ${config.sops.secrets."healthchecks/heartbeat_uuid".path})" >/dev/null
    '';
  };
  systemd.timers.heartbeat = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
    };
  };

  ###########################################################################
  # Prometheus / Alertmanager
  ###########################################################################
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";
    alertmanagers = [{static_configs = [{targets = ["127.0.0.1:9093"];}];}];
    rules = [
      (builtins.toJSON {
        groups = [
          {
            name = "homelab";
            rules = [
              {
                alert = "HostDown";
                expr = "up == 0";
                "for" = "5m";
                labels.severity = "critical";
                annotations.summary = "{{ $labels.instance }} is not answering scrapes";
              }
              {
                alert = "DiskAlmostFull";
                expr = ''(node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs"} / node_filesystem_size_bytes) < 0.15'';
                "for" = "30m";
                labels.severity = "warning";
                annotations.summary = "{{ $labels.instance }} {{ $labels.mountpoint }} below 15% free";
              }
              {
                alert = "SystemdUnitFailed";
                expr = ''node_systemd_unit_state{state="failed"} == 1'';
                "for" = "10m";
                labels.severity = "warning";
                annotations.summary = "{{ $labels.name }} failed on {{ $labels.instance }}";
              }
              {
                alert = "MemoryPressure";
                expr = "(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.1";
                "for" = "15m";
                labels.severity = "warning";
                annotations.summary = "{{ $labels.instance }} under 10% memory available";
              }
              {
                alert = "UpsOnBattery";
                expr = ''network_ups_tools_ups_status{flag="OB"} == 1'';
                "for" = "1m";
                labels.severity = "critical";
                annotations.summary = "UPS on battery";
              }
            ];
          }
        ];
      })
    ];
    scrapeConfigs =
      [
        {
          job_name = "node";
          static_configs = [{targets = nodeTargets;}];
        }
        {
          job_name = "blocky";
          static_configs = [{targets = ["127.0.0.1:4000"];}];
        }
      ]
      ++ lib.optional config.homelab.ups.enable {
        job_name = "nut";
        static_configs = [{targets = ["127.0.0.1:9199"];}];
      }
      ++ lib.optional cfg.unifi.enable {
        job_name = "unifi";
        static_configs = [{targets = ["127.0.0.1:9130"];}];
      };
    exporters.nut = lib.mkIf config.homelab.ups.enable {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9199;
      nutServer = "127.0.0.1";
    };
  };

  # Alerts -> HA webhook (an automation with webhook id "alertmanager"
  # forwards them to notify.*) and ntfy for you.
  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9093;
    configuration = {
      route = {
        receiver = "ntfy";
        group_by = ["alertname" "instance"];
        repeat_interval = "12h";
        routes = lib.optional (hassAddress != null) {
          receiver = "home-assistant";
          matchers = ["severity = critical"];
          continue = true;
        };
      };
      receivers =
        [
          {
            name = "ntfy";
            webhook_configs = [
              {
                url = "http://127.0.0.1:2586/ops";
                http_config.authorization = {
                  type = "Bearer";
                  credentials_file = config.sops.secrets."ntfy/token".path;
                };
              }
            ];
          }
        ]
        ++ lib.optional (hassAddress != null) {
          name = "home-assistant";
          webhook_configs = [{url = "http://${hassAddress}:8123/api/webhook/alertmanager";}];
        };
    };
  };

  services.prometheus.exporters.unpoller = lib.mkIf cfg.unifi.enable {
    enable = true;
    controllers = [
      {
        url = cfg.unifi.url;
        user = cfg.unifi.user;
        pass = config.sops.secrets."unifi/unpoller_password".path;
        verify_ssl = false;
      }
    ];
  };
  sops.secrets."unifi/unpoller_password" = lib.mkIf cfg.unifi.enable {owner = "unifi-poller";};

  ###########################################################################
  # Gatus: is it up, from inside the house; alerts to ntfy
  ###########################################################################
  services.gatus = {
    enable = true;
    environmentFile = config.sops.secrets."gatus/env".path;
    settings = {
      web = {
        address = "127.0.0.1";
        port = 8085;
      };
      alerting.ntfy = {
        url = "http://127.0.0.1:2586";
        topic = "ops";
        token = "\${NTFY_TOKEN}";
        default-alert = {
          enabled = true;
          failure-threshold = 3;
          success-threshold = 2;
          send-on-resolved = true;
        };
      };
      endpoints =
        lib.optional config.homelab.dns.enable {
          name = "dns-vip";
          group = "core";
          url = config.homelab.dns.vip;
          interval = "30s";
          dns = {
            query-name = "one.one.one.one";
            query-type = "A";
          };
          conditions = ["[DNS_RCODE] == NOERROR"];
          alerts = [{type = "ntfy";}];
        }
        ++ [
          {
            name = "proxy-tls";
            group = "core";
            url = "https://ha.${domain}/api/";
            interval = "1m";
            conditions = ["[STATUS] == 401" "[CERTIFICATE_EXPIRATION] > 168h"];
            alerts = [{type = "ntfy";}];
          }
          {
            name = "automations";
            group = "core";
            url = "http://127.0.0.1:${toString config.homelab.automations.healthPort}/";
            interval = "1m";
            conditions = ["[STATUS] == 200" "[BODY].status == UP"];
            alerts = [{type = "ntfy";}];
          }
        ]
        ++ lib.optional (hassAddress != null) {
          name = "home-assistant";
          group = "core";
          url = "http://${hassAddress}:8123/api/";
          interval = "1m";
          conditions = ["[STATUS] == 401"];
          alerts = [{type = "ntfy";}];
        };
    };
  };

  ###########################################################################
  # Grafana
  ###########################################################################
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3001;
        domain = "grafana.${domain}";
        root_url = "https://grafana.${domain}";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets."grafana/admin_password".path}}";
      };
      analytics.reporting_enabled = false;
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
    };
  };

  ###########################################################################
  # Homepage: every proxied service, generated from homelab.proxy.services
  ###########################################################################
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "home.${domain}";
    settings = {
      title = "Home";
      headerStyle = "clean";
    };
    services = [
      {
        Services =
          lib.mapAttrsToList (name: _: {
            ${name} = {href = "https://${name}.${domain}";};
          })
          (lib.filterAttrs (n: _: n != "home") config.homelab.proxy.services);
      }
    ];
  };

  homelab.proxy.services = {
    grafana = lib.mkDefault "http://127.0.0.1:3001";
    status = lib.mkDefault "http://127.0.0.1:8085";
    home = lib.mkDefault "http://127.0.0.1:8082";
    dns = lib.mkDefault "http://127.0.0.1:4000";
  };
})
