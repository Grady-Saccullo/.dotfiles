# LAN DNS: Blocky (ad/tracker blocking, custom names, encrypted upstreams)
# on every DNS-role host, behind one keepalived virtual IP that UniFi hands
# out as the resolver. Stateless, validated at build time, restarts on
# failure. No recursive resolver: two encrypted upstreams from different
# providers in parallel are the lower-maintenance choice.
{
  utils,
  config,
  lib,
  pkgs,
  hosts,
  hostName,
  ...
}:
utils.mkHomelabModule {
  path = "dns";
  inherit config;
  extraOptions = {
    vip = lib.mkOption {
      type = lib.types.str;
      description = "Virtual IP shared by all DNS hosts; the only resolver UniFi advertises.";
    };
    priority = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "VRRP priority; the highest live host holds the VIP.";
    };
    upstreams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "tcp-tls:dns.quad9.net:853"
        "tcp-tls:one.one.one.one:853"
      ];
    };
    blockLists = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # HaGeZi in Blocky's "wildcard asterisk" format. Pro supersedes the
      # ~50 small lists the Pi-hole used; the bypass list closes DoH/VPN
      # routes around the resolver (TVs).
      default = [
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/doh-vpn-proxy-bypass.txt"
      ];
    };
    allow = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Domains never blocked (exact + subdomains).";
    };
    deny = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra blocked domains (exact + subdomains).";
    };
    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Custom names: fqdn -> IP. Other modules contribute here.";
    };
  };
} (cfg: let
  inherit (config.homelab) lan domain;
  allowFile = pkgs.writeText "blocky-allow.txt" (lib.concatStringsSep "\n" cfg.allow);
  denyFile = pkgs.writeText "blocky-deny.txt" (lib.concatStringsSep "\n" cfg.deny);
  # Other hosts carrying the dns role are VRRP unicast peers.
  peers =
    lib.mapAttrsToList (_: h: h.address)
    (lib.filterAttrs (n: h: n != hostName && lib.elem "dns" h.roles) hosts);
  dnsCheck = pkgs.writeShellScript "keepalived-check-dns" ''
    exec ${pkgs.dnsutils}/bin/dig +short +time=1 +tries=1 @127.0.0.1 ${hostName}.${domain} | ${pkgs.gnugrep}/bin/grep -q .
  '';
in {
  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = 53;
        http = "127.0.0.1:4000"; # metrics + api, behind the proxy
      };
      upstreams = {
        groups.default = cfg.upstreams;
        strategy = "parallel_best";
        timeout = "2s";
        init.strategy = "fast";
      };
      bootstrapDns = [
        {upstream = "tcp+udp:9.9.9.9";}
        {upstream = "tcp+udp:1.1.1.1";}
      ];
      blocking = {
        denylists.default = cfg.blockLists ++ [(toString denyFile)];
        allowlists.default = [(toString allowFile)];
        clientGroupsBlock.default = ["default"];
        blockType = "zeroIp";
        loading = {
          strategy = "fast"; # answer queries before lists finish loading
          refreshPeriod = "24h";
          downloads.timeout = "60s";
        };
      };
      customDNS = {
        customTTL = "1h";
        filterUnmappedTypes = true;
        mapping = cfg.hosts;
      };
      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
      prometheus.enable = true;
      log.level = "warn";
    };
  };

  ###########################################################################
  # keepalived: one VIP across every DNS host, unicast VRRP, DNS health check
  ###########################################################################
  users.users.keepalived_script = {
    isSystemUser = true;
    group = "keepalived_script";
  };
  users.groups.keepalived_script = {};

  services.keepalived = {
    enable = true;
    openFirewall = true; # protocol 112 from the peers
    enableScriptSecurity = true;
    vrrpScripts.dns = {
      script = toString dnsCheck;
      interval = 2;
      fall = 2;
      rise = 2;
      user = "keepalived_script";
    };
    vrrpInstances.dns = {
      interface = lan.interface;
      state =
        if cfg.priority >= 150
        then "MASTER"
        else "BACKUP";
      virtualRouterId = 53;
      inherit (cfg) priority;
      virtualIps = [{addr = "${cfg.vip}/24";}];
      trackScripts = ["dns"];
      unicastSrcIp = lan.address;
      unicastPeers = peers;
    };
  };

  # <host>.<domain> for every machine in hosts/default.nix
  homelab.dns.hosts =
    lib.mapAttrs' (name: h: lib.nameValuePair "${name}.${domain}" h.address)
    hosts;

  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
})
