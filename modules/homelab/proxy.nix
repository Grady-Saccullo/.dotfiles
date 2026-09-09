# Caddy reverse proxy with publicly trusted certificates: one wildcard for
# `*.<domain>` issued through ACME DNS-01 on Cloudflare by the NixOS ACME
# module (lego), consumed by stock Caddy. No plugin builds, no private CA
# to install on phones. Each service is https://<name>.<domain>, and every
# name is registered as a Blocky custom entry pointing at this host.
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
      description = ''
        short name -> upstream URL, served as https://<name>.<domain>.
        Service modules register themselves here; add extra entries freely.
      '';
    };
    acmeEmail = lib.mkOption {
      type = lib.types.str;
    };
  };
} (cfg: let
  inherit (config.homelab) domain lan;
  fqdn = name: "${name}.${domain}";
in {
  assertions = [
    {
      assertion = !(lib.hasSuffix ".arpa" domain) && !(lib.hasSuffix ".local" domain);
      message = "homelab.domain must be a domain you own; ACME cannot issue for ${domain}";
    }
  ];

  sops.secrets."cloudflare/dns_token" = {};

  security.acme = {
    acceptTerms = true;
    defaults.email = cfg.acmeEmail;
    certs.${domain} = {
      inherit domain;
      extraDomainNames = ["*.${domain}"];
      dnsProvider = "cloudflare";
      # token scoped Zone:Read + DNS:Edit on the zone
      credentialFiles."CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare/dns_token".path;
      # the host resolves through Blocky; lego must see public DNS for the challenge
      dnsResolver = "1.1.1.1:53";
      group = "caddy";
      reloadServices = ["caddy.service"];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts =
      lib.mapAttrs' (name: upstream:
        lib.nameValuePair (fqdn name) {
          useACMEHost = domain;
          extraConfig = ''
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
