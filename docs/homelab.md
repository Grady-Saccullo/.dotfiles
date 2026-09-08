# homelab

Native NixOS replacement for the Debian 11 + docker-compose stack that ran
in `~/pi-docker-stuff` on the Raspberry Pi 4. The Pi is retired; the
services move to an x86 micro PC. Everything is a NixOS service; there is
no container runtime on the box.

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
from `configurations/homelab-nixos.nix`.

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
   `import "${inputs.homelab-private}/homelab.nix"` from the host config.
   Private inputs need ssh auth wherever `nix flake update` or a build runs,
   which with the deploy flow below is only the Mac.

Keys every enabled module expects are listed in
`secrets/homelab.example.yaml`. sops-nix fails activation on a missing key.

## Build and deploy flow

The micro PC builds its own closures; the Mac only needs ssh.

- `nix run .#install homelab root@<ip>`: one-time install with
  nixos-anywhere. Boots the target's disko layout, formats the disk,
  installs. Destructive.
- `nix run .#deploy homelab [user@host]`: copies the flake, builds on the
  target, activates with sudo. Use `-- boot` to defer activation.
- Later, GitHub Actions can build every configuration and push to cachix so
  deploys become pure downloads.

## Migration runbook

Debian on the Pi keeps running until the last step, so DNS for the house is
never down for more than the IP handover.

### 0. On the Pi (Debian), now

```sh
cd ~/pi-docker-stuff && docker stop influxdb portainer   # nothing reads them
```

Copy out of `zigbee-2-mqtt/data/configuration.yaml` the `advanced.network_key`
value, and note the Node-RED admin password (`adminAuth` in
`node-red/data/settings.js`). Make sure you can ssh from the Mac to the Pi;
step 4 pulls state over that connection.

### 1. Keys and secrets (Mac)

```sh
age-keygen -o ~/.config/sops/age/keys.txt        # once; public key -> .sops.yaml &admin
cp secrets/homelab.example.yaml secrets/homelab.yaml
$EDITOR secrets/homelab.yaml
sops --encrypt --in-place secrets/homelab.yaml   # host key gets added in step 3
```

Add your ssh public key to `users.users.<me>.openssh.authorizedKeys.keys`
in `configurations/homelab-nixos.nix`.

### 2. Prepare the micro PC

- BIOS: UEFI mode, secure boot off, "power on after power loss" on.
- Boot the NixOS minimal installer ISO from USB, set a root password
  (`sudo passwd`), note the IP (`ip a`) and the boot disk id
  (`ls -l /dev/disk/by-id`).
- Put that id in `configurations/homelab-configs/hardware.nix`.
- Give it a temporary address other than 192.168.1.2 for now: set
  `homelab.lan.address` to a free IP, e.g. `192.168.1.3`, until cutover.

```sh
nix run .#install homelab root@<installer-ip>
```

### 3. First boot

```sh
ssh hackerman@192.168.1.3 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
# add as &homelab in .sops.yaml, then:
sops updatekeys secrets/homelab.yaml
nix run .#deploy homelab hackerman@192.168.1.3
```

The first activation failed at the sops step (host wasn't a recipient);
this deploy fixes it and brings every service up empty.

### 4. Copy state from the Pi (on the micro PC, as root)

```sh
P=Patchwork7770@192.168.1.2:pi-docker-stuff
systemctl stop home-assistant zigbee2mqtt node-red

# Home Assistant: everything except db, logs, pip deps
rsync -a --exclude 'home-assistant_v2.db*' --exclude '*.log*' --exclude deps \
  $P/home-assistant/config/ /var/lib/hass/
rm -f /var/lib/hass/configuration.yaml                 # Nix owns this
rm -rf /var/lib/hass/custom_components/adaptive_lighting   # now from nixpkgs
chown -R hass:hass /var/lib/hass

# Zigbee2MQTT: paired devices, coordinator backup, database
rsync -a $P/zigbee-2-mqtt/data/ /var/lib/zigbee2mqtt/
python3 - <<'PY'
import yaml
old = yaml.safe_load(open('/var/lib/zigbee2mqtt/configuration.yaml'))
yaml.safe_dump(old.get('devices', {}), open('/var/lib/zigbee2mqtt/devices.yaml', 'w'))
yaml.safe_dump(old.get('groups', {}), open('/var/lib/zigbee2mqtt/groups.yaml', 'w'))
PY
rm /var/lib/zigbee2mqtt/configuration.yaml             # Nix owns this
chown -R zigbee2mqtt:zigbee2mqtt /var/lib/zigbee2mqtt

# Node-RED
rsync -a $P/node-red/data/ /var/lib/node-red/
chown -R node-red:node-red /var/lib/node-red
```

Then move the Zigbee dongle from the Pi to the micro PC (its
`/dev/serial/by-id` name travels with it) and start things:

```sh
systemctl start zigbee2mqtt home-assistant node-red
```

In the HA UI:

- MQTT integration: reconfigure to `127.0.0.1`, user `hass`, the sops password.
- Ring: add the core integration, remove ring-mqtt entities.
- Matter: add integration, server `ws://127.0.0.1:5580/ws`.
- Recorder starts empty on PostgreSQL. 14 days of history is the loss.

If Node-RED should keep its `adminAuth`, set
`homelab.node-red.settingsFile = "/var/lib/node-red/settings.js"`.

### 5. Verify on the temporary IP

```sh
dig @192.168.1.3 doubleclick.net           # blocked
dig @192.168.1.3 ha.home.arpa              # answers 192.168.1.3 for now
curl -k https://ha.home.arpa               # after trusting the Caddy root cert
systemctl --failed
```

Caddy root cert to trust on devices:
`/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`.
Tailscale: approve subnet route and exit node in the admin console, set
nameserver to this host, and optionally restrict it to `home.arpa`.

### 6. Cutover

1. Power off the Pi.
2. Set `homelab.lan.address = "192.168.1.2"` and deploy. Every client on
   the LAN and every phone using the router's DNS setting now talks to the
   new box without any change.
3. Remove the router port forward for 51820; phones use Tailscale.

Keep the Pi's SSD around for a couple of weeks as the fallback (plug it
back in and boot, and you are back on the old stack).

### 7. Afterwards

- Enable `homelab.backup` with a repository on the media box or a NAS.
- Reuse the Pi as a second AdGuard Home + Unbound instance (same `dns.nix`,
  `aarch64-linux` config) and advertise both DNS servers from the router,
  so a reboot of the main box never takes the house offline.

## New-home checklist

- Does the new router let you set the DHCP-advertised DNS server and
  static leases? If not, enable `services.adguardhome.settings.dhcp` and
  let this box do DHCP.
- Re-check the Zigbee channel against the new Wi-Fi channels
  (`homelab.zigbee2mqtt.channel`).
- Decide on Node-RED vs. HA automations + blueprints. Both run for now.
- Buy a domain for public certs if the internal CA annoys you.
- Second micro PC as media box: Jellyfin with QuickSync, ZFS, restic target.
  `hardware.nix` is the only file to copy and adjust.

## Not yet verified

This scaffold was written without a Nix evaluator available. Expect the
first `nix flake check` / build to surface small option-name mismatches.
Double check against the 26.05 module docs:

- `pkgs.home-assistant-custom-components.adaptive_lighting` attribute name
- AdGuard Home config path used in `dns.nix` (`/var/lib/AdGuardHome/AdGuardHome.yaml`)
- `services.node-red.configFile` accepting a non-store path
- disko partition attribute names for the current disko release
