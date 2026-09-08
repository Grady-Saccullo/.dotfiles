# hackerpi homelab

Native NixOS replacement for the Debian 11 + docker-compose stack that ran
in `~/pi-docker-stuff` on the Raspberry Pi 4. Everything is a NixOS
service; there is no container runtime on the box.

## What replaced what

| Old (docker)                    | New (NixOS)                                   | Why |
| ------------------------------- | --------------------------------------------- | --- |
| pihole-unbound                  | `services.adguardhome` + `services.unbound`   | Declarative, per-client rules, DoH/DoT capable, still recursive |
| home-assistant container        | `services.home-assistant`                     | Same app, packaged; config is Nix, UI-edited files still `!include`d |
| mariadb (recorder)              | `services.postgresql`, peer auth over socket   | No password to manage; recorder only keeps 14 days anyway |
| influxdb (269 GB, 41 % CPU)     | HA long-term statistics; Prometheus + Grafana | Nothing read the Influx data; Grafana wasn't even running |
| ring-mqtt                       | HA core `ring` integration + `go2rtc`         | No nixpkgs package; core integration now does live view |
| mosquitto (anonymous, loopback) | `services.mosquitto` with users + LAN listener | New-home devices (ESPHome/Shelly) can publish directly |
| zigbee2mqtt container           | `services.zigbee2mqtt`                        | Same coordinator + network key, no re-pairing |
| node-red container              | `services.node-red`                           | Flows carried over; revisit after the move |
| linuxserver/wireguard           | `services.tailscale` subnet router + exit node | No port forward, no hard-coded public IP |
| portainer                       | `systemctl` / `journalctl`                    | |
| nginx (dead since 2022)         | `services.caddy` with internal TLS            | `https://<svc>.home.arpa` for everything |
| (nothing)                       | `services.restic` + `postgresqlBackup`        | There were no backups |
| (nothing)                       | `services.matter-server`                      | Matter devices for the new place |

Module options live under `homelab.*` (see `modules/homelab/`), enabled
from `configurations/hackerpi-nixos.nix`.

## Secrets and private data

The dotfiles repo is public. Two mechanisms:

1. **Secrets (passwords, keys, tokens)** are encrypted with
   [sops-nix](https://github.com/Mic92/sops-nix) and committed in
   `secrets/`. Recipients are your personal age key and each host's age
   key derived from its ssh host key (`.sops.yaml`). Ciphertext in a public
   repo is fine; that is the design.
2. **Private-but-not-secret data** (device inventories, MAC addresses,
   floor-plan naming) can live in a private repo pulled in as a flake input
   (`homelab-private`, commented out in `flake.nix`). Only add it if you
   actually want to hide topology; LAN IPs and Zigbee friendly names are
   not worth the friction. If you do: `homelab-private.flake = false` and
   `import "${inputs.homelab-private}/hackerpi.nix"` from the host config.
   Private inputs need ssh auth wherever `nix flake update` or a build runs,
   which with the deploy flow below is only the Mac.

Keys every enabled module expects are listed in
`secrets/hackerpi.example.yaml`. sops-nix fails activation on a missing key.

## Build and deploy flow

Building on a 4 GB Pi is painful, so builds happen on the Mac:

- `nix.linux-builder` is enabled in `configurations/personal-darwin.nix`
  (aarch64-linux VM). First `nix run .#switch personal` downloads it.
- `nix run .#deploy hackerpi [user@host]` builds locally, pushes the closure
  over ssh, activates it with sudo, then pushes to cachix.
- `nix build .#nixosConfigurations.hackerpi.config.system.build.images.sd-card`
  produces a bootable image for first install.

## Migration runbook

The Pi's EEPROM boot order is SD first, then USB. Debian lives on the USB
SSD. That gives a free rollback: NixOS on the SD card, pull the card to
get Debian back. Keep Debian untouched until step 7.

### 0. Before touching the Pi (on Debian)

```sh
# influx is burning CPU for nothing; stop it now
cd ~/pi-docker-stuff && docker stop influxdb portainer

# state that carries over (~500 MB without influx/pihole logs)
tar czf ~/homelab-state.tgz -C ~/pi-docker-stuff \
  home-assistant/config zigbee-2-mqtt/data node-red/data mosquitto/data
```

Also copy the two values you'll need for secrets out of
`zigbee-2-mqtt/data/configuration.yaml` (`advanced.network_key`) and note
the Node-RED admin password (`adminAuth` in `node-red/data/settings.js`).

### 1. Keys and secrets (on the Mac)

```sh
age-keygen -o ~/.config/sops/age/keys.txt      # once; put the public key in .sops.yaml as &admin
cp secrets/hackerpi.example.yaml secrets/hackerpi.yaml
$EDITOR secrets/hackerpi.yaml                     # fill in real values
```

You cannot encrypt for the host yet (no host key exists). Encrypt for your
own key only for now and add the host after first boot:

```sh
sops --encrypt --in-place secrets/hackerpi.yaml
```

Add your ssh public key to `users.users.<me>.openssh.authorizedKeys.keys`
in `configurations/hackerpi-nixos.nix`.

### 2. Image

```sh
nix run .#switch personal        # picks up linux-builder
nix build .#nixosConfigurations.hackerpi.config.system.build.images.sd-card
# write result/sd-image/*.img to the 32 GB SD card (currently mmcblk0 in the Pi, unused)
```

### 3. First boot

Insert the SD card, power cycle. The Pi comes up on 192.168.1.2 (static),
so the house's DNS keeps working, now via AdGuard Home. Then:

```sh
ssh hackerman@192.168.1.2 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
# put the result in .sops.yaml as &hackerpi, then re-encrypt:
sops updatekeys secrets/hackerpi.yaml
nix run .#deploy hackerpi
```

Activation will fail on the first boot's sops step because the host key
wasn't a recipient; the deploy above fixes that. Everything is stateless up
to here.

### 4. Copy state (on the Pi, as root)

The Debian SSD is mounted read-only at `/mnt/legacy`.

```sh
L=/mnt/legacy/home/Patchwork7770/pi-docker-stuff
systemctl stop home-assistant zigbee2mqtt node-red

# Home Assistant: everything except the db, logs and pip deps
rsync -a --exclude 'home-assistant_v2.db*' --exclude '*.log*' --exclude deps \
  $L/home-assistant/config/ /var/lib/hass/
rm -f /var/lib/hass/configuration.yaml          # Nix writes this
# adaptive_lighting now comes from nixpkgs; keep hacs + nodered components
rm -rf /var/lib/hass/custom_components/adaptive_lighting
chown -R hass:hass /var/lib/hass

# Zigbee2MQTT: paired devices, coordinator backup, database
rsync -a $L/zigbee-2-mqtt/data/ /var/lib/zigbee2mqtt/
# devices/groups move out of configuration.yaml into their own files
python3 - <<'PY'
import yaml
old = yaml.safe_load(open('/var/lib/zigbee2mqtt/configuration.yaml'))
yaml.safe_dump(old.get('devices', {}), open('/var/lib/zigbee2mqtt/devices.yaml', 'w'))
yaml.safe_dump(old.get('groups', {}), open('/var/lib/zigbee2mqtt/groups.yaml', 'w'))
PY
rm /var/lib/zigbee2mqtt/configuration.yaml      # Nix writes this
chown -R zigbee2mqtt:zigbee2mqtt /var/lib/zigbee2mqtt

# Node-RED
rsync -a $L/node-red/data/ /var/lib/node-red/
chown -R node-red:node-red /var/lib/node-red

systemctl start zigbee2mqtt home-assistant node-red
```

Then in the HA UI:

- MQTT integration: reconfigure to `127.0.0.1`, user `hass`, the sops password.
- Ring: add the core integration, remove the ring-mqtt entities.
- Matter: add integration, server `ws://127.0.0.1:5580/ws`.
- Recorder starts empty on PostgreSQL. 14 days of history is the loss.

If Node-RED should keep its `adminAuth`, set
`homelab.node-red.settingsFile = "/var/lib/node-red/settings.js"` and deploy.

### 5. Verify

```sh
dig @192.168.1.2 doubleclick.net           # blocked
dig @192.168.1.2 ha.home.arpa              # 192.168.1.2
curl -k https://ha.home.arpa               # HA login
systemctl --failed
```

Trust Caddy's root cert on your devices:
`/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`.

Tailscale: approve the subnet route and exit node in the admin console;
set DNS -> nameserver 192.168.1.2, "override local DNS", restrict to
`home.arpa` if you prefer split DNS.

### 6. Cut over WireGuard clients

Phones/laptops use Tailscale. Remove the router port forward for 51820.

### 7. Root on the SSD

Once stable for a couple of weeks: write the same image to the SSD
(`dd` from the Mac or from the Pi with the SD as root), boot with the SD
card removed, delete the `/mnt/legacy` mount from `hardware.nix`. The
Debian install is gone at this point; make sure `homelab-state.tgz` is
somewhere else first. Optionally enable `homelab.backup` now with the SD
card (or a NAS) as the restic repository.

## New-home checklist

- Does the new router let you set the DHCP-advertised DNS server? If not,
  turn on `services.adguardhome.settings.dhcp` and let the Pi do DHCP.
- Re-check Zigbee channel vs. the new Wi-Fi channels (`homelab.zigbee2mqtt.channel`).
- Decide on Node-RED vs. HA automations + blueprints. Both run for now.
- Buy a domain for public certs if the internal CA annoys you.
- Pi 4 is fine for this load without Influx; a Pi 5 or N100 box would be a
  drop-in (`hardware.nix` is the only hardware-specific file).

## Not yet verified

This scaffold was written without a Nix evaluator available. Expect the
first `nix flake check` / build on the Mac to surface small option-name
mismatches. Things to double check against the 26.05 module docs:

- `pkgs.home-assistant-custom-components.adaptive_lighting` attribute name
- AdGuard Home config path used in `dns.nix` (`/var/lib/AdGuardHome/AdGuardHome.yaml`)
- `services.node-red.configFile` accepting a non-store path
- `image.modules.sd-card` being available for aarch64 in 26.05
