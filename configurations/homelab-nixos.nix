# homelab: x86 micro PC running the house services. Replaces the Raspberry
# Pi's Debian + docker-compose stack (pi-docker-stuff) with native NixOS
# services. See docs/homelab.md.
{
  inputs,
  config,
  me,
  ...
}: let
  inherit (inputs) self;
in {
  imports = [
    self.nixosModules.sensible
    self.nixosModules.homelab
    self.homeManagerModules.nixosModule
    self.applications
    ./homelab-configs/hardware.nix
  ];

  time.timeZone = "America/Los_Angeles";

  users.users.${me.user}.openssh.authorizedKeys.keys = [
    # TODO: paste the public key(s) you ssh from. Password auth is disabled.
    # "ssh-ed25519 AAAA... hackerman@mbp"
  ];

  # Static LAN address. The router hands this IP out as the DNS server. It
  # inherits the Pi's address at cutover so no client config changes.
  networking = {
    useDHCP = false;
    interfaces.${config.homelab.lan.interface}.ipv4.addresses = [
      {
        address = config.homelab.lan.address;
        prefixLength = 24;
      }
    ];
    defaultGateway = config.homelab.lan.gateway;
    # The host resolves through its own AdGuard Home instance.
    nameservers = ["127.0.0.1"];
  };

  homelab = {
    domain = "home.arpa";
    lan = {
      interface = "eth0";
      address = "192.168.1.2";
      cidr = "192.168.1.0/24";
      gateway = "192.168.1.1";
    };

    secrets = {
      enable = true;
      file = ../secrets/homelab.yaml;
    };

    # AdGuard Home (replaces Pi-hole) in front of a local recursive Unbound.
    dns = {
      enable = true;
      # Lists carried over from the Pi-hole gravity.db. Pruned to the ones
      # that are still maintained; the hagezi lists supersede most of the
      # small single-purpose lists Pi-hole was pulling.
      blockLists = {
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
        "NextDNS native LG/Samsung/Sonos/etc" = "https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/samsung";
      };
      # From the Pi-hole domainlist (allow, deny, regex).
      userRules = [
        "@@||open.spotify.com^"
        "@@||alive.github.com^"
        "@@||cdn.jsdelivr.net^"
        "@@||cdn.shopify.com^"
        "@@||i.scdn.co^"
        "@@||googleapis.com^"
        "@@||split.io^"
        "@@||activitypub.rocks^"
        "@@||sentry.io^"
        "@@||amplitude.com^"
        "@@||heapanalytics.com^"
        "@@||cdn.heapanalytics.com^"
        "@@||facebook.com^"
        "@@||fbcdn.net^"
        "@@||fb.me^"
        "@@||redirector.gvt1.com^"
        "@@||branch.io^"
        "@@||script.google.com^"
        "@@||rippling.com^"
        "||updates.bravesoftware.com^"
        "||cletra.com^"
        "||googlesyndication.com^"
        "||googletagmanager.com^"
        "||2mdn.net^"
        # LG webOS TV telemetry / ads
        "||alphonso.tv^"
        "||lgsmartad.com^"
        "||lgtvcommon.com^"
        "||lgtvsdp.com^"
        "||lgsmartplatform.com^"
        "||nextlgsdp.com^"
        "||ueiwsp.com^"
      ];
    };

    mqtt.enable = true;

    zigbee2mqtt = {
      enable = true;
      serialPort = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_4ae1008bcc60ec11962b417625bfaa52-if00-port0";
      channel = 11;
    };

    home-assistant = {
      enable = true;
      homekitPort = 21065;
    };

    matter.enable = true;

    # Existing flows carry over; decide after the move whether HA's own
    # automation editor + blueprints cover them (docs/homelab.md).
    node-red.enable = true;

    tailscale = {
      enable = true;
      advertiseRoutes = [config.homelab.lan.cidr];
      exitNode = true;
    };

    proxy = {
      enable = true;
      services = {
        ha = "http://127.0.0.1:8123";
        zigbee = "http://127.0.0.1:8080";
        nodered = "http://127.0.0.1:1880";
        dns = "http://127.0.0.1:3000";
        grafana = "http://127.0.0.1:3001";
      };
    };

    monitoring.enable = true;

    # Turn on after a restic repository + password are in secrets/.
    backup = {
      enable = false;
      repository = "/mnt/backup/restic";
    };
  };

  # CLI comfort on the box itself (all home-manager based, shared with the
  # Macs). Heavy dev tooling stays off.
  applications = {
    bat.enable = true;
    btop.enable = true;
    direnv.enable = true;
    eza.enable = true;
    fzf.searchPaths = ["$HOME" "/var/lib" "/etc/nixos"];
    jq.enable = true;
    neovim.enable = true;
    ripgrep.enable = true;
    starship.enable = true;
    tmux.enable = true;
    yazi.enable = true;
    zoxide.enable = true;
  };
}
