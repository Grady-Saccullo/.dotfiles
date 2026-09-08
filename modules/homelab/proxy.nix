# Caddy reverse proxy: one https://<name>.<domain> per service, certs from
# Caddy's internal CA. Registers each name as a DNS rewrite in AdGuard Home
# so it resolves on the LAN and over Tailscale.
#
# Devices need to trust the CA root once:
#   /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
# If you'd rather have publicly valid certs, buy a domain and switch to the
# ACME DNS-01 challenge (caddy.withPlugins + a DNS provider plugin).
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "proxy";
  inherit config;
  extraOptions = {
    services = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "short name -> upstream URL, served as <name>.<domain>.";
    };
  };
} (cfg: let
  inherit (config.homelab) domain lan;
  fqdn = name: "${name}.${domain}";
in {
  services.caddy = {
    enable = true;
    virtualHosts =
      lib.mapAttrs' (name: upstream:
        lib.nameValuePair (fqdn name) {
          extraConfig = ''
            tls internal
            reverse_proxy ${upstream}
          '';
        })
      cfg.services;
  };

  homelab.dns.hosts =
    lib.mapAttrs' (name: _: lib.nameValuePair (fqdn name) lan.address)
    cfg.services;

  networking.firewall.allowedTCPPorts = [80 443];
})
