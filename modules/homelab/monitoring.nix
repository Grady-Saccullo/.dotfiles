# Prometheus + node exporter + Alertmanager + Grafana. The lightweight
# replacement for the InfluxDB/Grafana pair: host metrics out of the box,
# alerts delivered through a Home Assistant webhook (so they reach the
# companion app / ntfy via a normal HA automation). HA can push its own
# metrics via the `prometheus` integration (uncomment the scrape job and
# create a long-lived token).
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "monitoring";
  inherit config;
} (cfg: let
  domain = config.homelab.domain;
in {
  sops.secrets."grafana/admin_password".owner = "grafana";

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";
    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = ["systemd"];
    };
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
            ];
          }
        ];
      })
    ];
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{targets = ["127.0.0.1:9100"];}];
      }
      # {
      #   job_name = "home-assistant";
      #   metrics_path = "/api/prometheus";
      #   bearer_token_file = config.sops.secrets."home-assistant/prometheus_token".path;
      #   static_configs = [{targets = ["127.0.0.1:8123"];}];
      # }
    ];
  };

  # Alerts -> HA webhook. Create an automation with a Webhook trigger id
  # "alertmanager" that forwards {{ trigger.json.alerts }} to notify.*.
  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9093;
    configuration = {
      route = {
        receiver = "home-assistant";
        group_by = ["alertname" "instance"];
        repeat_interval = "12h";
      };
      receivers = [
        {
          name = "home-assistant";
          webhook_configs = [{url = "http://127.0.0.1:8123/api/webhook/alertmanager";}];
        }
      ];
    };
  };

  homelab.proxy.services.grafana = lib.mkDefault "http://127.0.0.1:3001";

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
})
