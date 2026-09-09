# Homelab service modules. Each file exposes `homelab.<name>.enable` (see
# utils.mkHomelabModule) and configures a *native* NixOS service. Home
# Assistant itself runs as a HAOS virtual machine (hass-vm.nix); everything
# HA-adjacent lives inside that VM as add-ons.
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  imports = [
    ./secrets.nix
    ./network.nix
    ./dns.nix
    ./proxy.nix
    ./hass-vm.nix
    ./automations.nix
    ./tailscale.nix
    ./monitoring.nix
    ./ntfy.nix
    ./backup.nix
    ./ups.nix
    ./jellyfin.nix
    ./maintenance.nix
  ];

  options.homelab = {
    domain = mkOption {
      type = types.str;
      description = ''
        Zone every service hangs under, e.g. `home.example.com` on a domain
        you own, so ACME DNS-01 can issue publicly trusted certificates.
      '';
    };

    lan = {
      interface = mkOption {
        type = types.str;
        default = "eno1";
        description = "Physical NIC. Untagged = Infra VLAN, IoT tagged on top.";
      };
      address = mkOption {
        type = types.str;
        description = "This host's static IPv4 address on the Infra VLAN.";
      };
      cidr = mkOption {
        type = types.str;
        description = "Infra VLAN subnet in CIDR notation.";
      };
      gateway = mkOption {
        type = types.str;
      };
    };

    iot = {
      vlan = mkOption {
        type = types.int;
        default = 30;
        description = "802.1Q tag of the IoT VLAN, trunked to this host for the HA VM.";
      };
      bridge = mkOption {
        type = types.str;
        default = "br-iot";
      };
      cidr = mkOption {
        type = types.str;
        description = "IoT VLAN subnet, advertised to Tailscale and used in firewall notes.";
      };
    };
  };
}
