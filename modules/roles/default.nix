# Roles bundle homelab.* services so a host is described by what it is for
# (hosts/default.nix) rather than by a list of switches. Everything is
# mkDefault so a host file can still turn individual pieces off.
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault mkIf mkMerge;
  cfg = config.homelab.roles;
  on = mkDefault true;
in {
  options.homelab.roles = {
    dns.enable = mkEnableOption "LAN DNS: AdGuard Home + Unbound";
    home-automation.enable = mkEnableOption "Home Assistant and friends";
    monitoring.enable = mkEnableOption "Prometheus, Alertmanager, Grafana";
    media.enable = mkEnableOption "Jellyfin media server";
    # Only for a network WITHOUT a UniFi gateway (UDM/UCG already runs the
    # controller, DHCP, VLANs and mDNS reflection).
    network.enable = mkEnableOption "self-hosted UniFi controller + Kea DHCP";
  };

  config = mkMerge [
    # Every NixOS host: secrets, remote access, https front door.
    {
      homelab.secrets.enable = on;
      homelab.tailscale.enable = on;
      homelab.proxy.enable = on;
    }
    (mkIf cfg.dns.enable {
      homelab.dns.enable = on;
    })
    (mkIf cfg.home-automation.enable {
      homelab = {
        mqtt.enable = on;
        zigbee2mqtt.enable = on;
        home-assistant.enable = on;
        matter.enable = on;
        music-assistant.enable = on;
        voice.enable = on;
        esphome.enable = on;
        ntfy.enable = on;
      };
    })
    (mkIf cfg.monitoring.enable {
      homelab.monitoring.enable = on;
    })
    (mkIf cfg.media.enable {
      homelab.jellyfin.enable = on;
    })
    (mkIf cfg.network.enable {
      homelab.unifi.enable = on;
      homelab.dhcp.enable = on;
    })
  ];
}
