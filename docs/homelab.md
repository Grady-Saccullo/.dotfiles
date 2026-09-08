# homelab

Native NixOS replacement for the Debian 11 + docker-compose stack that ran
in `~/pi-docker-stuff` on the Raspberry Pi 4. The Pi is retired; the
services move to x86 micro PCs. Everything is a NixOS service; there is no
container runtime on any box.

## Layout

```
hosts/default.nix          one entry per NixOS machine: address, roles, ssh host key
hosts/keys.nix             admin ssh public keys installed on every host
hosts/<name>/default.nix   host-only settings (timezone, static IP, zigbee port, ...)
hosts/<name>/hardware.nix  boot, disko disk layout, udev rules
modules/roles/             dns | home-automation | monitoring | media | network
modules/homelab/<svc>.nix  one native service each, `homelab.<svc>.enable`
modules/nixos/sensible.nix base for every NixOS host (users, ssh, nix, watchdog)
secrets/<host>.yaml        sops-encrypted secrets, one file per host
apps/install, apps/deploy  nixos-anywhere first install / nixos-rebuild over ssh
.github/workflows/nix.yml  builds every host on CI and pushes to cachix
```

Adding a machine is one entry in `hosts/default.nix` plus a `hosts/<name>/`
directory. Everything else (ssh config on the Macs, known_hosts on every
host, DNS names, Prometheus targets, flake checks) is derived from it.

## What replaced what

| Old (docker)                    | New (NixOS)                                    | Why |
| ------------------------------- | ---------------------------------------------- | --- |
| pihole-unbound                  | `services.adguardhome` + `services.unbound`    | Declarative, per-client rules, UI edits merge back, still recursive |
| home-assistant container        | `services.home-assistant`                      | Same app, packaged; config is Nix, UI-edited files still `!include`d |
| mariadb (recorder)              | `services.postgresql`, peer auth over socket    | No password to manage; recorder keeps 14 days anyway |
| influxdb (269 GB, 41 % CPU)     | HA long-term statistics; Prometheus + Grafana  | Nothing read the Influx data |
| ring-mqtt                       | HA core `ring` integration + HA-managed go2rtc | No nixpkgs package; the core integration does live view now |
| mosquitto (anonymous, loopback) | `services.mosquitto`, users + LAN listener      | ESPHome/Shelly devices can publish directly |
| zigbee2mqtt container           | `services.zigbee2mqtt`                         | Same coordinator + network key, no re-pairing |
| node-red container              | `services.node-red` (migration only)           | See "Automations as code" |
| linuxserver/wireguard           | `services.tailscale` subnet router + exit node  | No port forward, no hard-coded public IP, Tailscale SSH |
| portainer                       | `systemctl` / `journalctl`                     | |
| nginx (dead since 2022)         | `services.caddy`, internal TLS                 | `https://<svc>.home.arpa` for everything |
| Sonos app                       | Music Assistant                                | See "Music" |
| google_translate TTS            | wyoming piper + faster-whisper + openWakeWord  | Local voice for Assist |
| (nothing)                       | Matter server, ESPHome dashboard, ntfy         | New-home devices and cloud-free push |
| (nothing)                       | Alertmanager -> HA webhook, restic backups     | There were no alerts or backups |

## Network

The UniFi gateway keeps doing what it does best: DHCP with static leases,
VLANs, the controller, mDNS reflection. The homelab box only needs:

- The gateway's DHCP handing out `192.168.1.2` as the DNS server.
- An **IoT VLAN** for the TV, Sonos, Ring, ESPHome and Zigbee-adjacent
  devices, with the homelab box allowed to reach it (HA, mDNS, MQTT) and
  the IoT side allowed to reach only the box. This is the new-house
  security win; DNS blocking of TV telemetry is a weak substitute.
- Tailscale: approve the subnet route and exit node, set the tailnet DNS
  nameserver to `192.168.1.2` (optionally split on `home.arpa`), and
  restrict Tailscale SSH in the ACL to your user.

The `network` role (self-hosted controller + Kea DHCP) exists for a network
without a UniFi gateway and stays off here. HA's `unifi` integration gives
presence detection from the gateway.

## Automations as code

Node-RED did the complex flows (MQTT devices, ESP devices, lighting,
activity, audio, Sonos). Recommendation: keep HA as the bus and put the
logic in one small service you own, deployed from this flake like every
other service.

- HA exposes everything over one websocket: every state change as an
  event, every action as a service call. MQTT stays available for
  low-latency device work. That is the whole interface.
- **Digital Alchemy** (TypeScript) is the best fit for your toolchain: it
  generates types for your actual entities, so `hass.entity.light.kitchen`
  is checked at compile time, and it runs as a plain Node process. Write
  it as a normal repo, build it with Nix, expose it as
  `homelab.automations` running as a systemd unit. AppDaemon (Python) is
  the established alternative and is packaged in nixpkgs.
- HA's own automations + blueprints stay for the trivial stuff (motion ->
  light) where a YAML file beats code.
- Node-RED remains installed only to read the old flows while porting;
  set `homelab.node-red.enable = false` in `hosts/homelab/default.nix`
  when done.

## Music

Music Assistant (`homelab.music-assistant`, on in the home-automation role)
is the answer to both problems:

- It has its own clean web UI (installable as a PWA on phones and a wall
  tablet) that non-technical people can use: pick a room, pick a
  playlist, play. Nobody needs the HA app for music.
- It drives Sonos today and whatever replaces Sonos tomorrow: AirPlay 2
  speakers, WiiM, Chromecast, DLNA, and **Snapcast** for a DIY multi-room
  build (a Pi Zero 2 or ESP32 with a DAC per room, all sample-synced, MA
  runs the Snapcast server itself). Sources: Spotify, local library,
  radio, YouTube Music, Tidal, Qobuz.
- Physical controls: Zigbee buttons/dials (IKEA Symfonisk controller,
  Hue tap) mapped in automations to MA players. Guests never open an app.
- Everything MA does is also an HA media_player, so the automations-as-code
  service can script it (announcements, follow-me audio, wake-up).

If MA's UI still isn't right for the household, a small custom PWA over
HA's websocket API is a weekend project; the state and controls are all
there.

## Secrets and private data

The repo is public. Two mechanisms:

1. **Secrets** (passwords, keys, tokens) are encrypted with sops-nix and
   committed in `secrets/`. Recipients: your personal age key and each
   host's age key derived from its ssh host key (`.sops.yaml`).
2. **Private-but-not-secret data** can live in a private repo pulled in as
   a flake input (`homelab-private`, commented out in `flake.nix`). Only
   worth it if you want to hide topology; LAN IPs and Zigbee names are not.

Keys every enabled module expects are listed in
`secrets/homelab.example.yaml`. sops-nix fails activation on a missing key.

## Build and deploy flow

- `nix run .#install homelab root@<ip>` one-time install with
  nixos-anywhere. Formats the disk per its disko layout. Destructive.
- `nix run .#deploy homelab` copies the flake, builds on the target,
  activates with sudo. `-- boot` defers activation.
- CI (`.github/workflows/nix.yml`) builds every NixOS host and pushes to
  cachix on each push to main. Add `CACHIX_AUTH_TOKEN` to the repo secrets
  once; deploys then become downloads and
  `homelab.maintenance.autoUpgrade` becomes safe to enable.

## Migration runbook

Debian on the Pi keeps running until cutover.

### 0. On the Pi (Debian), now

```sh
cd ~/pi-docker-stuff && docker stop influxdb portainer
```

Values to carry into secrets: `advanced.network_key` from
`zigbee-2-mqtt/data/configuration.yaml`, `_credentialSecret` from
`node-red/data/.config.runtime.json`.

### 1. Keys and secrets (Mac)

```sh
age-keygen -o ~/.config/sops/age/keys.txt       # once; public key -> .sops.yaml &admin
ssh-keygen -t ed25519 -N "" -f /tmp/homelab/etc/ssh/ssh_host_ed25519_key
ssh-to-age < /tmp/homelab/etc/ssh/ssh_host_ed25519_key.pub   # -> .sops.yaml &homelab
cp secrets/homelab.example.yaml secrets/homelab.yaml
$EDITOR secrets/homelab.yaml
sops --encrypt --in-place secrets/homelab.yaml
```

Put your ssh public key in `hosts/keys.nix`. Generating the host key here
and shipping it at install (next step) means the very first activation can
already decrypt; there is no failed-first-boot dance.

### 2. Install the micro PC

- BIOS: UEFI, secure boot off, **power on after AC loss** on.
- Boot the NixOS minimal ISO, `sudo passwd`, note `ip a` and the boot
  disk from `ls -l /dev/disk/by-id`; put the latter in
  `hosts/homelab/hardware.nix`.
- Give the box a temporary address: set `address = "192.168.1.3"` in
  `hosts/default.nix` until cutover.

```sh
chmod 600 /tmp/homelab/etc/ssh/ssh_host_ed25519_key
nix run .#install homelab root@<installer-ip> -- --extra-files /tmp/homelab
nix run .#deploy homelab hackerman@192.168.1.3       # first full activation
ssh-keyscan -t ed25519 192.168.1.3                   # -> sshHostKey in hosts/default.nix
```

### 3. Copy state from the Pi (on the micro PC, as root)

```sh
P=Patchwork7770@192.168.1.2:pi-docker-stuff
systemctl stop home-assistant zigbee2mqtt node-red

rsync -a --exclude 'home-assistant_v2.db*' --exclude '*.log*' --exclude deps \
  $P/home-assistant/config/ /var/lib/hass/
rm -f /var/lib/hass/configuration.yaml                     # Nix owns this
rm -rf /var/lib/hass/custom_components/adaptive_lighting   # now from nixpkgs
chown -R hass:hass /var/lib/hass

rsync -a $P/zigbee-2-mqtt/data/ /var/lib/zigbee2mqtt/
python3 - <<'PY'
import yaml
old = yaml.safe_load(open('/var/lib/zigbee2mqtt/configuration.yaml'))
yaml.safe_dump(old.get('devices', {}), open('/var/lib/zigbee2mqtt/devices.yaml', 'w'))
yaml.safe_dump(old.get('groups', {}), open('/var/lib/zigbee2mqtt/groups.yaml', 'w'))
PY
rm /var/lib/zigbee2mqtt/configuration.yaml                 # Nix owns this
chown -R zigbee2mqtt:zigbee2mqtt /var/lib/zigbee2mqtt

rsync -a $P/node-red/data/ /var/lib/node-red/
chown -R node-red:node-red /var/lib/node-red
```

Move the Zigbee dongle over (its `/dev/serial/by-id` name travels with
it), then `systemctl start zigbee2mqtt home-assistant node-red`.

In the HA UI: MQTT integration -> `127.0.0.1`, user `hass`; add Ring
(core), Matter (`ws://127.0.0.1:5580/ws`), Music Assistant, Wyoming
(whisper `tcp://127.0.0.1:10300`, piper `:10200`, openWakeWord `:10400`),
ntfy. Recorder starts empty on PostgreSQL; 14 days of history is the loss.

### 4. Verify on the temporary IP

```sh
dig @192.168.1.3 doubleclick.net           # blocked
dig @192.168.1.3 ha.home.arpa              # 192.168.1.3 for now
systemctl --failed
```

Trust the Caddy root cert on your devices:
`/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`.

### 5. Cutover

1. Power off the Pi.
2. `address = "192.168.1.2"` in `hosts/default.nix`, deploy. Every LAN
   client keeps working without changes.
3. Remove the gateway port forward for 51820; phones use Tailscale.

Keep the Pi's SSD for a couple of weeks as the fallback.

### 6. Afterwards

- Enable `homelab.backup` with a repository on the media box or a NAS,
  plus an offsite copy (Backblaze B2 via `environmentFile`).
- Bring the Pi back as a second DNS node (`roles = ["dns"]`,
  `aarch64-linux`) and advertise both resolvers from the gateway.
- Media box: copy `hosts/homelab/hardware.nix`, add a `media` entry with
  `roles = ["media" "dns"]`, ZFS for the library, Jellyfin with QuickSync.

## Not yet verified

Written without a Nix evaluator; the first `nix flake check` will surface
small option-name mismatches. Least certain:

- `services.music-assistant.providers` names, and whether the module opens
  its ports itself (8095/8097 are opened explicitly here).
- `services.wyoming.*` option names in 26.05.
- disko partition attribute names for the current disko release.
- `programs.ssh.enableDefaultConfig` on the home-manager revision in use.
