# Nightly restic backup of service state to Backblaze B2 (or any restic
# repository), with the failure paths wired: a start ping, a success ping
# from ExecStartPost, an OnFailure unit that pings the failure URL, and a
# monthly read-data check. The cleanup hook runs even on failure, so it
# cannot carry the success ping.
{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkHomelabModule {
  path = "backup";
  inherit config;
  extraOptions = {
    repository = lib.mkOption {
      type = lib.types.str;
      description = "restic repository, e.g. b2:bucket:homelab or sftp:user@host:/srv/restic";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/var/lib/hass-backups" # HA's own encrypted backups
        "/var/lib/grafana"
        "/var/lib/private/ha-automations"
        "/var/lib/ntfy-sh"
        "/var/lib/acme"
      ];
    };
  };
} (cfg: let
  hc = "https://hc-ping.com";
  uuid = config.sops.secrets."healthchecks/backup_uuid".path;
  ping = suffix:
    pkgs.writeShellScript "hc-ping-${lib.replaceStrings ["/"] ["-"] suffix}" ''
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 "${hc}/$(cat ${uuid})${suffix}" >/dev/null || true
    '';
in {
  sops.secrets."restic/password" = {};
  sops.secrets."restic/env" = {}; # B2_ACCOUNT_ID / B2_ACCOUNT_KEY
  sops.secrets."healthchecks/backup_uuid" = {};

  services.restic.backups.homelab = {
    inherit (cfg) repository paths;
    passwordFile = config.sops.secrets."restic/password".path;
    environmentFile = config.sops.secrets."restic/env".path;
    initialize = true;
    backupPrepareCommand = ''
      ${pkgs.restic}/bin/restic unlock || true
      ${ping "/start"}
    '';
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
      RandomizedDelaySec = "20m";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    checkOpts = ["--read-data-subset=10%"];
  };

  systemd.services.restic-backups-homelab = {
    serviceConfig.ExecStartPost = toString (ping "");
    unitConfig.OnFailure = ["hc-fail@%n.service"];
  };
  systemd.services."hc-fail@" = {
    description = "healthchecks.io failure ping for %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = toString (ping "/fail");
    };
  };
})
