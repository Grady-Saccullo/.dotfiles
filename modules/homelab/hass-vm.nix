# Home Assistant OS as a libvirt VM, declared with NixVirt. HA updates
# itself, keeps A/B boot slots, runs Zigbee2MQTT / Mosquitto / ring-mqtt /
# voice as add-ons, and backs itself up to an NFS share on this host.
#
# What is declarative here (three of HA's four layers):
#   1. the VM: domain, IoT-bridge NIC, USB passthrough of the Zigbee dongle,
#      image pinned by hash and copied to a mutable qcow2 on first boot;
#   2. the config directory (hosts/<host>/hass) pushed over the SSH add-on
#      by `hass-sync` on every deploy, secrets rendered from sops;
#   3. the add-on set and options reconciled by `hass-addons` through the
#      Supervisor API HA proxies at /api/hassio/.
# Layer 4 (.storage: config entries, registries, pairings) is state and is
# covered by HA's own scheduled backups into /var/lib/hass-backups, which
# restic then ships offsite.
{
  utils,
  config,
  lib,
  pkgs,
  inputs,
  hostName,
  ...
}:
utils.mkHomelabModule {
  path = "hass";
  inherit config;
  imports = [inputs.nixvirt.nixosModules.default];
  extraOptions = {
    address = lib.mkOption {
      type = lib.types.str;
      description = "The VM's fixed IPv4 lease on the IoT VLAN (set in UniFi).";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "18.2";
      description = "HAOS release to seed the disk with. HAOS updates itself afterwards.";
    };
    imageHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-JU5T81TfBznjr8Cb5UMaB99T8N9rcDiFQE9mXEVPJU4="; # haos_ova-18.2.qcow2.xz, from the GitHub release digest
      description = "SRI hash of haos_ova-<version>.qcow2.xz; change with `version`.";
    };
    memoryMiB = lib.mkOption {
      type = lib.types.int;
      default = 6144;
    };
    vcpus = lib.mkOption {
      type = lib.types.int;
      default = 4;
    };
    zigbee = {
      vendorId = lib.mkOption {
        type = lib.types.int;
        default = 4292; # 0x10c4 Silicon Labs CP210x (Sonoff Zigbee 3.0 Dongle Plus)
      };
      productId = lib.mkOption {
        type = lib.types.int;
        default = 60000; # 0xea60
      };
    };
    imageDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/vms/haos";
    };
    configDir = lib.mkOption {
      type = lib.types.path;
      description = "Version-controlled HA configuration directory pushed into /config.";
    };
    repositories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "https://github.com/zigbee2mqtt/hassio-zigbee2mqtt"
        "https://github.com/tsightler/ring-mqtt-ha-addon"
      ];
      description = "Third-party add-on repositories to register before installing add-ons.";
    };
    addons = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = ''
        Add-on slug -> options object. Values may use sops placeholders; the
        whole set is rendered by sops-nix at activation, never in the store.
      '';
    };
  };
} (cfg: let
  inherit (config.homelab) iot domain;
  nixvirt = inputs.nixvirt.lib;
  image = pkgs.fetchurl {
    url = "https://github.com/home-assistant/operating-system/releases/download/${cfg.version}/haos_ova-${cfg.version}.qcow2.xz";
    hash = cfg.imageHash;
  };
  disk = "${cfg.imageDir}/haos.qcow2";
  bridgeName = iot.bridge;

  base = nixvirt.domain.templates.linux {
    name = "haos";
    uuid = "1ab21b47-6b48-4d1a-9f6c-6b7d0c6e3a01";
    memory = {
      count = cfg.memoryMiB;
      unit = "MiB";
    };
    storage_vol = disk;
    bridge_name = bridgeName;
    virtio_video = false;
  };

  domain =
    base
    // {
      vcpu = {
        placement = "static";
        count = cfg.vcpus;
      };
      on_crash = "restart";
      devices =
        base.devices
        // {
          controller = [
            {
              type = "scsi";
              index = 0;
              model = "virtio-scsi";
            }
          ];
          disk = map (d:
            d
            // {
              driver = (d.driver or {}) // {discard = "unmap";};
              target = {
                dev = "sda";
                bus = "scsi";
              };
            })
          base.devices.disk;
          interface = map (i: i // {trustGuestRxFilters = true;}) base.devices.interface;
          # Zigbee coordinator by vendor/product id, so re-enumeration cannot
          # lose it; optional so a missing dongle does not kill the domain.
          hostdev = [
            {
              type = "usb";
              mode = "subsystem";
              managed = true;
              source = {
                startupPolicy = "optional";
                vendor.id = cfg.zigbee.vendorId;
                product.id = cfg.zigbee.productId;
              };
            }
          ];
        };
    };

  haUrl = "http://${cfg.address}:8123";
  # curl wrapper: admin long-lived token from sops
  api = pkgs.writeShellScript "hass-api" ''
    set -euo pipefail
    token=$(cat ${config.sops.secrets."hass/token".path})
    method=$1; path=$2; shift 2
    exec ${pkgs.curl}/bin/curl -fsS -m 120 -X "$method" \
      -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
      "${haUrl}/api$path" "$@"
  '';
in {
  ###########################################################################
  # Hypervisor
  ###########################################################################
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "start";
    # default "suspend" breaks USB passthrough on resume
    onShutdown = "shutdown";
    shutdownTimeout = 240; # HAOS 18 takes ~2 min to stop cleanly
    qemu = {
      ovmf.enable = true;
      swtpm.enable = false;
    };
  };

  virtualisation.libvirt = {
    enable = true;
    connections."qemu:///system".domains = [
      {
        definition = nixvirt.domain.writeXML domain;
        active = true;
        # a nixpkgs bump that moves OVMF must not force-restart the house
        restart = false;
      }
    ];
  };

  # Seed the disk once. Never run from the store path (read-only) and never
  # use a backing store (HAOS updates rewrite its boot slots).
  systemd.services.haos-image = {
    description = "Seed the Home Assistant OS disk image";
    wantedBy = ["multi-user.target"];
    before = ["nixvirt.service" "libvirtd.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p ${cfg.imageDir}
      # qcow2 on btrfs: no copy-on-write for the VM image
      ${pkgs.e2fsprogs}/bin/chattr +C ${cfg.imageDir} 2>/dev/null || true
      if [ ! -e ${disk} ]; then
        ${pkgs.xz}/bin/xz -dc ${image} > ${disk}.tmp
        mv ${disk}.tmp ${disk}
      fi
    '';
  };

  ###########################################################################
  # Backups: HA writes its scheduled, encrypted backups to this NFS export;
  # restic (backup.nix) ships the directory offsite.
  ###########################################################################
  services.nfs.server = {
    enable = true;
    exports = ''
      /var/lib/hass-backups ${cfg.address}(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
    '';
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/hass-backups 0770 nobody nogroup - -"
  ];
  networking.firewall.allowedTCPPorts = [2049];

  ###########################################################################
  # Layer 2: configuration directory + rendered secrets, pushed on deploy
  ###########################################################################
  sops.secrets."hass/token" = {};
  sops.secrets."hass/ssh_key" = {};
  sops.secrets."hass/ssh_pubkey" = {};
  sops.secrets."mqtt/hass" = {};
  sops.secrets."mqtt/zigbee2mqtt" = {};

  sops.templates."hass-secrets.yaml".content = ''
    # rendered by sops-nix on ${hostName}; pushed to /config/secrets.yaml
    mqtt_password: ${config.sops.placeholder."mqtt/hass"}
    external_url: https://ha.${domain}
  '';

  systemd.services.hass-sync = {
    description = "Push the version-controlled Home Assistant config into the VM";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "nixvirt.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # a changed config directory changes this unit, so switch re-runs it
    restartTriggers = [cfg.configDir config.sops.templates."hass-secrets.yaml".content];
    script = ''
      set -euo pipefail
      key=${config.sops.secrets."hass/ssh_key".path}
      ssh="${pkgs.openssh}/bin/ssh -i $key -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"
      # wait for HA to answer
      for i in $(seq 1 60); do
        ${api} GET /config >/dev/null 2>&1 && break
        sleep 5
      done
      ${pkgs.rsync}/bin/rsync -a --no-owner --no-group --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r \
        -e "$ssh" ${cfg.configDir}/ root@${cfg.address}:/config/
      ${pkgs.rsync}/bin/rsync -a --no-owner --no-group --chmod=Fu=rw,Fgo= \
        -e "$ssh" ${config.sops.templates."hass-secrets.yaml".path} root@${cfg.address}:/config/secrets.yaml
      # reload_all runs check_config first and aborts on errors
      ${api} POST /services/homeassistant/reload_all >/dev/null
    '';
  };

  ###########################################################################
  # Layer 3: add-ons reconciled through the Supervisor API
  ###########################################################################
  sops.templates."hass-addons.json".content = builtins.toJSON {
    inherit (cfg) repositories;
    addons = cfg.addons;
  };

  systemd.services.hass-addons = {
    description = "Reconcile Home Assistant add-ons and their options";
    wantedBy = ["multi-user.target"];
    after = ["hass-sync.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    restartTriggers = [config.sops.templates."hass-addons.json".content];
    script = ''
      set -euo pipefail
      spec=${config.sops.templates."hass-addons.json".path}
      jq=${pkgs.jq}/bin/jq
      for repo in $($jq -r '.repositories[]' "$spec"); do
        ${api} POST /hassio/store/repositories -d "$($jq -cn --arg r "$repo" '{repository:$r}')" >/dev/null || true
      done
      for slug in $($jq -r '.addons | keys[]' "$spec"); do
        state=$(${api} GET "/hassio/addons/$slug/info" | $jq -r '.data.state // "missing"' || echo missing)
        if [ "$state" = "missing" ]; then
          ${api} POST "/hassio/store/addons/$slug/install" >/dev/null
        fi
        options=$($jq -c --arg s "$slug" '.addons[$s]' "$spec")
        ${api} POST "/hassio/addons/$slug/options" \
          -d "$($jq -cn --argjson o "$options" '{options:$o, boot:"auto", watchdog:true}')" >/dev/null
        ${api} POST "/hassio/addons/$slug/start" >/dev/null || true
      done
    '';
  };

  homelab.proxy.services.ha = lib.mkDefault haUrl;
})
