# Homelab service modules. Each file exposes `homelab.<name>.enable` (see
# utils.mkHomelabModule) and configures a *native* NixOS service; nothing
# here runs in a container.
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  imports = [
    ./secrets.nix
    ./dns.nix
    ./mqtt.nix
    ./zigbee2mqtt.nix
    ./home-assistant.nix
    ./matter.nix
    ./node-red.nix
    ./tailscale.nix
    ./proxy.nix
    ./monitoring.nix
    ./backup.nix
  ];

  options.homelab = {
    domain = mkOption {
      type = types.str;
      default = "home.arpa";
      description = ''
        Internal DNS zone. `home.arpa` is the RFC 8375 reserved zone for
        exactly this. Service hostnames are `<service>.<domain>`.
      '';
    };

    lan = {
      interface = mkOption {
        type = types.str;
        default = "eth0";
      };
      address = mkOption {
        type = types.str;
        description = "Static IPv4 address of this host on the LAN.";
      };
      cidr = mkOption {
        type = types.str;
        description = "LAN subnet in CIDR notation.";
      };
      gateway = mkOption {
        type = types.str;
      };
    };
  };
}
