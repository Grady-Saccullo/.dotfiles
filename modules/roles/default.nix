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
    dns.enable = mkEnableOption "LAN DNS: Blocky behind the keepalived VIP";
    home-automation.enable = mkEnableOption "the Home Assistant OS VM and its automations daemon";
    monitoring.enable = mkEnableOption "Prometheus, Alertmanager, Grafana, Gatus, Homepage";
    media.enable = mkEnableOption "Jellyfin media server";
  };

  config = mkMerge [
    # Every NixOS host: secrets, remote access, https front door, push.
    {
      homelab.secrets.enable = on;
      homelab.tailscale.enable = on;
      homelab.proxy.enable = on;
      homelab.ntfy.enable = on;
    }
    (mkIf cfg.dns.enable {
      homelab.dns.enable = on;
    })
    (mkIf cfg.home-automation.enable {
      homelab.hass.enable = on;
      homelab.automations.enable = on;
    })
    (mkIf cfg.monitoring.enable {
      homelab.monitoring.enable = on;
    })
    (mkIf cfg.media.enable {
      homelab.jellyfin.enable = on;
    })
  ];
}
