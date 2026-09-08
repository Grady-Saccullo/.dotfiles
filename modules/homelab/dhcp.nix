# Kea DHCPv4 with static leases in Nix. Turn on when the router either
# can't advertise a custom DNS server or you want hostnames to be data in
# this repo. Reservations are also registered as AdGuard rewrites so
# <name>.<domain> resolves without relying on the router.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "dhcp";
  inherit config;
  extraOptions = {
    pool = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.100 - 192.168.1.250";
    };
    reservations = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          mac = lib.mkOption {type = lib.types.str;};
          ip = lib.mkOption {type = lib.types.str;};
        };
      });
      default = {};
      description = "hostname -> { mac, ip } static leases.";
    };
  };
} (cfg: let
  inherit (config.homelab) lan domain;
in {
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [lan.interface];
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      valid-lifetime = 86400;
      renew-timer = 43200;
      rebind-timer = 75600;
      subnet4 = [
        {
          id = 1;
          subnet = lan.cidr;
          pools = [{inherit (cfg) pool;}];
          option-data = [
            {
              name = "routers";
              data = lan.gateway;
            }
            {
              name = "domain-name-servers";
              data = lan.address;
            }
            {
              name = "domain-name";
              data = domain;
            }
          ];
          reservations =
            lib.mapAttrsToList (name: r: {
              hostname = name;
              hw-address = r.mac;
              ip-address = r.ip;
            })
            cfg.reservations;
        }
      ];
    };
  };

  homelab.dns.hosts =
    lib.mapAttrs' (name: r: lib.nameValuePair "${name}.${domain}" r.ip)
    cfg.reservations;

  networking.firewall.allowedUDPPorts = [67];
})
