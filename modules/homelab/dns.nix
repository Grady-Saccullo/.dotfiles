# LAN DNS: AdGuard Home (ad/tracker blocking, per-client rules, query log,
# DNS rewrites, web UI) in front of a local recursive Unbound resolver, so
# no upstream provider sees the household's queries.
#
# Replaces the pihole-unbound container. AdGuard Home's config is seeded
# from Nix but `mutableSettings = true` merges rather than overwrites, so
# allow/deny rules added from the query log in the UI survive rebuilds.
{
  utils,
  config,
  lib,
  pkgs,
  hosts,
  ...
}:
utils.mkHomelabModule {
  path = "dns";
  inherit config;
  extraOptions = {
    blockLists = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Blocklist name -> URL (AdGuard/hosts format).";
      # The hagezi lists supersede most of the ~50 small single-purpose
      # lists the Pi-hole was pulling; the rest are still maintained.
      default = {
        "HaGeZi Multi PRO" = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
        "HaGeZi Threat Intelligence" = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt";
        "HaGeZi Gambling" = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/gambling-onlydomains.txt";
        "StevenBlack" = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        "OISD small" = "https://small.oisd.nl";
        "Firebog EasyPrivacy" = "https://v.firebog.net/hosts/Easyprivacy.txt";
        "Firebog AdGuard DNS" = "https://v.firebog.net/hosts/AdguardDNS.txt";
        "Firebog Admiral" = "https://v.firebog.net/hosts/Admiral.txt";
        "URLhaus" = "https://urlhaus.abuse.ch/downloads/hostfile";
        "Perflyst Amazon FireTV" = "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt";
        "NextDNS native Samsung" = "https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/samsung";
      };
    };
    userRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "AdGuard filter rules, e.g. \"||ads.example^\" or \"@@||allowed.example^\".";
    };
    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "DNS rewrites: fqdn -> IP. Other modules (proxy) contribute here.";
    };
    webPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };
  };
} (cfg: let
  unboundPort = 5335;
  stateDir = "/var/lib/AdGuardHome";
  configFile = "${stateDir}/AdGuardHome.yaml";
  adminSecret = config.sops.secrets."adguard/admin_password_hash".path;
in {
  services.resolved.enable = false;

  ###########################################################################
  # Unbound: recursive, validating, loopback only.
  ###########################################################################
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings.server = {
      # do-ip6 is off below, so no ::1 listener (unbound refuses to bind it)
      interface = lib.mkForce ["127.0.0.1"];
      port = unboundPort;
      access-control = lib.mkForce ["127.0.0.0/8 allow"];

      do-ip6 = false;
      prefer-ip6 = false;
      num-threads = 1;
      edns-buffer-size = 1232;
      so-rcvbuf = "1m";

      harden-glue = true;
      harden-dnssec-stripped = true;
      use-caps-for-id = false;
      qname-minimisation = true;
      aggressive-nsec = true;

      prefetch = true;
      cache-min-ttl = 0;
      cache-max-ttl = 86400;

      private-address = [
        "192.168.0.0/16"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "10.0.0.0/8"
        "fd00::/8"
        "fe80::/10"
      ];
    };
  };

  ###########################################################################
  # AdGuard Home
  ###########################################################################
  sops.secrets."adguard/admin_password_hash" = {};

  services.adguardhome = {
    enable = true;
    host = "127.0.0.1"; # web UI is reached through the caddy proxy
    port = cfg.webPort;
    mutableSettings = true;
    settings = {
      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;
        upstream_dns = ["127.0.0.1:${toString unboundPort}"];
        bootstrap_dns = ["9.9.9.9" "1.1.1.1"];
        # unbound already validates DNSSEC
        enable_dnssec = false;
        ratelimit = 0;
        cache_size = 4194304;
        cache_optimistic = true;
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        rewrites =
          lib.mapAttrsToList (domain: answer: {inherit domain answer;})
          cfg.hosts;
      };
      filters =
        lib.imap1 (i: entry: {
          id = 1000 + i;
          enabled = true;
          inherit (entry) name;
          url = entry.value;
        })
        (lib.attrsToList cfg.blockLists);
      user_rules = cfg.userRules;
      querylog = {
        enabled = true;
        interval = "168h";
      };
      statistics = {
        enabled = true;
        interval = "168h";
      };
    };
  };

  # The admin password hash comes from sops at runtime and is spliced into
  # the live config after the module has written it, so the hash never
  # lands in the nix store or in this public repo. Runs as root ("+").
  systemd.services.adguardhome.serviceConfig.ExecStartPre = lib.mkAfter [
    "+${pkgs.writeShellScript "adguardhome-set-admin" ''
      set -euo pipefail
      hash=$(cat ${adminSecret})
      ${lib.getExe pkgs.yq-go} -i '.users = [{"name": "admin", "password": "'"$hash"'"}]' ${configFile}
    ''}"
  ];

  homelab.proxy.services.dns = lib.mkDefault "http://127.0.0.1:${toString cfg.webPort}";

  # <host>.<domain> for every machine in hosts/default.nix
  homelab.dns.hosts =
    lib.mapAttrs' (name: h: lib.nameValuePair "${name}.${config.homelab.domain}" h.address)
    hosts;

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
})
