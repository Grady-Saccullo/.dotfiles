# homelab: x86 micro PC running the house services. Replaces the Raspberry
# Pi's Debian + docker-compose stack (pi-docker-stuff). Roles come from
# hosts/default.nix; only host-specific settings live here.
{
  inputs,
  config,
  ...
}: let
  inherit (inputs) self;
in {
  imports = [
    self.nixosModules.sensible
    self.nixosModules.homelab
    self.homeManagerModules.nixosModule
    self.applications
    ./hardware.nix
  ];

  time.timeZone = "America/Los_Angeles";

  # Static LAN address (hosts/default.nix). The router hands this IP out as
  # the DNS server; it inherits the Pi's address at cutover.
  networking = {
    useDHCP = false;
    interfaces.${config.homelab.lan.interface}.ipv4.addresses = [
      {
        address = config.homelab.lan.address;
        prefixLength = 24;
      }
    ];
    defaultGateway = config.homelab.lan.gateway;
    nameservers = ["127.0.0.1"]; # resolves through its own AdGuard Home
  };

  homelab = {
    domain = "home.arpa";
    lan = {
      interface = "eth0";
      cidr = "192.168.1.0/24";
      gateway = "192.168.1.1";
    };

    # Carried over from the Pi-hole domainlist (allow / deny / regex).
    dns.userRules = [
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

    zigbee2mqtt = {
      serialPort = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_4ae1008bcc60ec11962b417625bfaa52-if00-port0";
      channel = 11;
    };

    home-assistant.homekitPort = 21065;

    # Kept only to migrate the existing flows. The replacement is
    # automations-as-code against HA's websocket API (docs/homelab.md,
    # "Automations as code"); turn this off once the flows are ported.
    node-red.enable = true;

    tailscale = {
      advertiseRoutes = [config.homelab.lan.cidr];
      exitNode = true;
    };

    # Turn on after a restic repository + password are in secrets/.
    backup = {
      enable = false;
      repository = "/mnt/backup/restic";
    };

    # Turn on once CI builds this configuration on every push to main.
    maintenance.autoUpgrade.enable = false;
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
