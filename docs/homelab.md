# homelab

The house runs on two x86 micro PCs under NixOS 26.05. Home Assistant is
Home Assistant OS in a libvirt VM on the IoT VLAN; everything else is a
native NixOS service. The rationale, research and equipment list live in
the published plan ("Just-Works Homelab"); this file is the operating
manual for the repo.

## Layout

```
hosts/default.nix           one entry per NixOS machine: address, roles, ssh host key
hosts/keys.nix              admin ssh public keys installed on every host
hosts/homelab/default.nix   host settings: domain, VLANs, DNS lists, add-ons, VM address
hosts/homelab/hardware.nix  boot, disko btrfs subvolumes, btrbk, udev
hosts/homelab/hass/         Home Assistant configuration, pushed into the VM
automations/                the TypeScript automations daemon
modules/roles/              dns | home-automation | monitoring | media
modules/homelab/<svc>.nix   one native service each, `homelab.<svc>.enable`
modules/nixos/sensible.nix  base for every NixOS host
secrets/<host>.yaml         sops-encrypted secrets, one file per host
apps/install, apps/deploy   nixos-anywhere first install / nixos-rebuild over ssh
.github/workflows/nix.yml   builds every host, validates the HA config, pushes to cachix
```

## What runs where

| Layer | Where | Module |
| --- | --- | --- |
| DNS: Blocky behind a keepalived VIP, encrypted upstreams, HaGeZi lists | NixOS, every `dns` host | `dns.nix` |
| TLS: wildcard cert by ACME DNS-01 on Cloudflare, stock Caddy | NixOS | `proxy.nix` |
| Home Assistant OS VM, IoT-bridge NIC, Zigbee dongle passthrough | NixOS libvirt | `hass-vm.nix` |
| HA config push + add-on reconcile | NixOS oneshots on every deploy | `hass-vm.nix` |
| Mosquitto, Zigbee2MQTT, ring-mqtt, Speech-to-Phrase, whisper, piper, SSH | HAOS add-ons | `hosts/homelab/default.nix` |
| Automations daemon | NixOS systemd | `automations.nix` |
| Prometheus, Alertmanager, Grafana, Gatus, Homepage, heartbeat | NixOS | `monitoring.nix` |
| ntfy | NixOS | `ntfy.nix` |
| restic to B2 with healthchecks pings | NixOS | `backup.nix` |
| NUT for the UPS | NixOS | `ups.nix` |
| Tailscale subnet router | NixOS | `tailscale.nix` |
| Jellyfin | NixOS, `media` host | `jellyfin.nix` |

## Network

UniFi zone-based firewall, one zone per VLAN: Infra (both boxes, the DNS
VIP, Caddy), Personal, Work, IoT (TVs, Sonos, Apple TVs, Hue, the HA VM,
Voice PE, printer), Untrusted (guest Wi-Fi, cloud gadgets, the server's
remote power plug), Cameras if Protect arrives.

| # | From | To | Match | Action |
| --- | --- | --- | --- | --- |
| 1 | Personal, Work | IoT (Work: the "cast targets" device group) | any | Allow, auto-return |
| 2 | IoT | Personal, Work | TCP 1400, 3400, 3401, 3500 | Allow (Sonos events) |
| 3 | IoT (Apple TV) | Personal, Work | UDP 49152–65535 | Allow only if AirPlay drops |
| 4 | IoT (HA VM) | Infra (this host) | TCP 2049, 3493 | Allow (backups NFS, UPS) |
| 5 | All | Infra, DNS VIP only | TCP+UDP 53 | Allow |
| 6 | All | External | TCP 853, DoH app category | Block |
| NAT | each LAN interface | | dst port 53 | DNAT to the VIP |
| default | IoT, Untrusted | Personal, Work, Infra | any | Block |

Settings: mDNS proxy on Personal, Work and IoT (custom: `_airplay`,
`_raop`, `_hap`, `_sonos`, `_spotify-connect`, `_companion-link`,
`_googlecast`), off elsewhere. IGMP snooping on with unknown multicast
flooded on the IoT VLAN. Wi-Fi multicast enhancement off on the IoT SSID.
IPv6 on IoT only. DHCP hands out the DNS VIP on every network; the HA VM
gets a fixed lease matching `homelab.hass.address`.

On the host, `network.nix` puts the untagged NIC on Infra and tags the IoT
VLAN into `br-iot`, which only the VM uses.

## Secrets

sops-nix, one encrypted file per host in `secrets/`, recipients in
`.sops.yaml` (your age key plus the host's ssh-derived key). Every key an
enabled module needs is listed in `secrets/homelab.example.yaml`.
Add-on options and HA's `secrets.yaml` are rendered by sops at activation,
so passwords never enter the Nix store.

## Build and deploy

- `nix run .#install homelab root@<installer-ip> -- --extra-files <dir>`:
  one-time nixos-anywhere install. Destructive.
- `nix run .#deploy homelab`: copies the flake, builds on the target,
  activates. `hass-sync` and `hass-addons` re-run when their inputs change.
- CI builds the host, validates `hosts/homelab/hass` with the official HA
  container, and pushes to cachix. Add `CACHIX_AUTH_TOKEN` to the repo.
- No auto-upgrade. Deploy by hand on a schedule after a green CI run.

## Runbook

### 0. Before the move, on the Mac

1. Buy the domain, put its DNS on Cloudflare, create a token scoped
   Zone:Read + DNS:Edit. Set `homelab.domain` and `proxy.acmeEmail`.
2. `age-keygen`, add your key to `.sops.yaml`; add your ssh public key to
   `hosts/keys.nix`.
3. Generate the host ssh key locally and add its age form to `.sops.yaml`:
   ```sh
   install -d -m755 /tmp/homelab/etc/ssh
   ssh-keygen -t ed25519 -N "" -f /tmp/homelab/etc/ssh/ssh_host_ed25519_key
   ssh-to-age < /tmp/homelab/etc/ssh/ssh_host_ed25519_key.pub   # -> &homelab
   ```
4. Generate the HA ssh keypair (`hass/ssh_key`, `hass/ssh_pubkey`),
   create the healthchecks.io checks, the B2 bucket, the Tailscale auth
   key. Fill `secrets/homelab.yaml` from the example and encrypt it. The
   `hass/token` comes later, after HA's first login.
5. On the Pi: `docker stop influxdb portainer`, then in HA take a full
   backup (Settings > System > Backups) and download it. Copy the Zigbee
   data directory too:
   `rsync -a pi:pi-docker-stuff/zigbee-2-mqtt/data/ ./z2m-data/`.

### 1. Install the micro PC

BIOS: UEFI, secure boot off, power on after AC loss. Boot the NixOS
installer, `sudo passwd`, note `ip link` (set `homelab.lan.interface`) and
the boot disk id (`hosts/homelab/hardware.nix`). For the first days set
`address` in `hosts/default.nix` to a spare Infra IP so the Pi keeps
serving DNS.

```sh
chmod 600 /tmp/homelab/etc/ssh/ssh_host_ed25519_key
nix run .#install homelab root@<installer-ip> -- --extra-files /tmp/homelab
```

The first activation seeds the HAOS disk and starts the VM. `hass-sync`
and `hass-addons` will fail until HA is onboarded; that is expected.

### 2. Seed Home Assistant

1. Open `http://<hass address>:8123`, choose "restore from backup", upload
   the Pi's backup. HA restores users, integrations, automations, HACS
   remnants, everything in `.storage`.
2. Create a long-lived token (profile > security), put it in
   `secrets/homelab.yaml` as `hass/token` and in `ha-automations.env`.
3. `nix run .#deploy homelab`. `hass-addons` registers the repositories,
   installs Mosquitto, Zigbee2MQTT, ring-mqtt, Speech-to-Phrase, whisper,
   piper and SSH with their options; `hass-sync` pushes
   `hosts/homelab/hass` and `secrets.yaml`, then reloads.
4. Before starting Zigbee2MQTT for the first time, copy the Pi's Zigbee
   data into the add-on's directory so the network key and pairings carry
   over: `scp -r ./z2m-data/* root@<hass>:/config/zigbee2mqtt/` (the
   add-on's `data_path`). Delete the old `configuration.yaml` inside it;
   the add-on writes its own from the options. Move the dongle over, start
   the add-on, check the devices are online.
5. Settings > System > Storage: add the NFS backup share
   (`<host infra IP>:/var/lib/hass-backups`) and make it the default;
   set the backup schedule. Save the encryption key in 1Password.
6. In the HA UI: MQTT integration to `core-mosquitto`, user `hass`; add
   Wyoming for whisper, piper and Speech-to-Phrase; add ring-mqtt's
   devices; Matter only if a device forces it.

### 3. Verify

```sh
dig @<dns vip> doubleclick.net          # 0.0.0.0
dig @<dns vip> ha.<domain>              # host infra IP
curl -sS https://ha.<domain>/api/       # 401 with a valid public cert
systemctl --failed
virsh list                              # haos running
```

### 4. Cutover

Power off the Pi, set `address` back to `192.168.1.2`, deploy, point the
UniFi DHCP DNS field at the VIP, remove the WireGuard port forward. Keep
the Pi's SSD for two weeks.

### 5. Afterwards

Second box with `roles = ["dns" "media"]`: the VIP fails over, restic gets
a second target. Enable `homelab.automations` once the lock file and hash
exist (see `automations/README.md`). Enable `monitoring.unifi` after
creating the local read-only user on the console.

## Known gaps

Written without a Nix evaluator; the first `nix flake check` will surface
option-name mismatches. Least certain, in order:

- NixVirt template arguments (`bridge_name`, `storage_vol` as a path) and
  the shape of `base.devices` used for the overrides in `hass-vm.nix`.
- HAOS add-on slugs for ring-mqtt and Speech-to-Phrase; confirm in the
  add-on's URL.
- The Mosquitto add-on's option schema (the `logins` list).
- `services.prometheus.exporters.unpoller` option names.
- Alertmanager posting to ntfy delivers raw JSON; acceptable, ugly.
