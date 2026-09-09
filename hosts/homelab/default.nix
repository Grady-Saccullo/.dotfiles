# homelab: x86 micro PC running the house. Roles come from hosts/default.nix
# (dns, home-automation, monitoring); only host-specific settings live here.
# Home Assistant OS runs as a VM on the IoT VLAN; everything else is a
# native NixOS service. See docs/homelab.md.
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

  homelab = {
    # TODO: a domain you own, with DNS on Cloudflare. Certificates for
    # *.home.example.com are issued through DNS-01; nothing is exposed.
    domain = "home.example.com";

    lan = {
      interface = "eno1"; # `ip link` on the installer
      address = "192.168.1.2";
      cidr = "192.168.1.0/24";
      gateway = "192.168.1.1";
    };
    iot = {
      vlan = 30;
      cidr = "10.30.0.0/24";
    };

    dns = {
      vip = "192.168.1.53";
      priority = 150; # this box holds the VIP when both DNS hosts are up
      # Carried over from the Pi-hole allow / deny lists.
      allow = [
        "open.spotify.com"
        "alive.github.com"
        "cdn.jsdelivr.net"
        "cdn.shopify.com"
        "i.scdn.co"
        "googleapis.com"
        "split.io"
        "activitypub.rocks"
        "sentry.io"
        "amplitude.com"
        "heapanalytics.com"
        "facebook.com"
        "fbcdn.net"
        "fb.me"
        "redirector.gvt1.com"
        "branch.io"
        "script.google.com"
        "rippling.com"
      ];
      deny = [
        "updates.bravesoftware.com"
        "cletra.com"
        "googlesyndication.com"
        "googletagmanager.com"
        "2mdn.net"
        # LG webOS TV telemetry / ads
        "alphonso.tv"
        "lgsmartad.com"
        "lgtvcommon.com"
        "lgtvsdp.com"
        "lgsmartplatform.com"
        "nextlgsdp.com"
        "ueiwsp.com"
      ];
    };

    proxy.acmeEmail = "gradysaccullo@gmail.com";

    hass = {
      address = "10.30.0.10"; # fixed lease in UniFi for the VM's MAC
      configDir = ./hass;
      # Slugs: Settings > Add-ons > (add-on) > URL shows the slug.
      addons = {
        core_mosquitto = {
          logins = [
            {
              username = "hass";
              password = config.sops.placeholder."mqtt/hass";
            }
            {
              username = "zigbee2mqtt";
              password = config.sops.placeholder."mqtt/zigbee2mqtt";
            }
          ];
          require_certificate = false;
          certfile = "fullchain.pem";
          keyfile = "privkey.pem";
          customize = {
            active = false;
            folder = "mosquitto";
          };
        };
        "45df7312_zigbee2mqtt" = {
          data_path = "/config/zigbee2mqtt";
          socat = {
            enabled = false;
            master = "pty,raw,echo=0,link=/tmp/ttyZ2M,mode=777";
            slave = "tcp-listen:8485,keepalive,nodelay,reuseaddr,keepidle=1,keepintvl=1,keepcnt=5";
            options = "-d -d";
            log = false;
          };
          mqtt = {
            server = "mqtt://core-mosquitto:1883";
            user = "zigbee2mqtt";
            password = config.sops.placeholder."mqtt/zigbee2mqtt";
          };
          serial = {
            port = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_4ae1008bcc60ec11962b417625bfaa52-if00-port0";
            adapter = "zstack";
          };
        };
        "03b2ae9d_ring-mqtt" = {
          mqtt_url = "mqtt://hass:${config.sops.placeholder."mqtt/hass"}@core-mosquitto:1883";
          enable_cameras = true;
          enable_modes = false;
          enable_panic = false;
          hass_topic = "homeassistant/status";
          ring_topic = "ring";
        };
        core_ssh = {
          authorized_keys = [config.sops.placeholder."hass/ssh_pubkey"];
          password = "";
          apks = [];
          server.tcp_forwarding = false;
        };
        core_speech-to-phrase = {};
        core_whisper = {
          model = "base-int8";
          language = "en";
          beam_size = 1;
        };
        core_piper = {
          voice = "en_US-lessac-medium";
        };
      };
    };

    # Enable after `npm install` in ./automations produced package-lock.json
    # and `prefetch-npm-deps` gave the hash.
    automations.enable = false;

    tailscale.advertiseRoutes = [config.homelab.lan.cidr config.homelab.iot.cidr];

    ups.enable = true;

    monitoring.unifi = {
      enable = false; # turn on after creating the local read-only user on the console
      url = "https://192.168.1.1";
    };

    backup = {
      enable = true;
      repository = "b2:homelab-backups:homelab";
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
