# Prometheus + node exporter + Grafana. The lightweight replacement for the
# InfluxDB/Grafana pair: host metrics out of the box; HA can push its own
# via the `prometheus` integration (uncomment the scrape job and create a
# long-lived token).
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
