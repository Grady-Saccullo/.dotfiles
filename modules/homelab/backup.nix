# Nightly restic backup of all service state plus a PostgreSQL dump. The
# old stack had no backups at all. Repository can be a local disk, an SFTP
# host, or S3/B2 (add credentials via `environmentFile`).
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "backup";
  inherit config;
  extraOptions = {
    repository = lib.mkOption {
      type = lib.types.str;
      description = "restic repository, e.g. /mnt/backup/restic or sftp:user@host:/srv/restic";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/var/lib/hass"
        "/var/lib/zigbee2mqtt"
        "/var/lib/node-red"
        "/var/lib/AdGuardHome"
        "/var/lib/mosquitto"
        "/var/lib/matter-server"
        "/var/backup/postgresql"
      ];
    };
  };
} (cfg: {
  sops.secrets."restic/password" = {};

  services.postgresqlBackup = {
    enable = true;
    databases = ["hass"];
    startAt = "*-*-* 02:30:00";
  };

  services.restic.backups.homelab = {
    inherit (cfg) repository paths;
    passwordFile = config.sops.secrets."restic/password".path;
    initialize = true;
    exclude = [
      "/var/lib/hass/home-assistant.log*"
      "/var/lib/hass/deps"
      "/var/lib/node-red/node_modules"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
})
