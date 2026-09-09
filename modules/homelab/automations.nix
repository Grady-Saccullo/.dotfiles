# The automations daemon: a small TypeScript service on Home Assistant's
# own websocket library for the stateful logic that YAML fights you on.
# Source lives in ./automations at the repo root and is built here with
# buildNpmPackage; a new build changes the unit's ExecStart, so a deploy
# restarts it. Rules the daemon follows are in the runbook.
{
  utils,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
utils.mkHomelabModule {
  path = "automations";
  inherit config;
  extraOptions = {
    npmDepsHash = lib.mkOption {
      type = lib.types.str;
      default = lib.fakeHash;
      description = "From `prefetch-npm-deps automations/package-lock.json`; the first build prints it.";
    };
    healthPort = lib.mkOption {
      type = lib.types.port;
      default = 9111;
    };
  };
} (cfg: let
  daemon = pkgs.buildNpmPackage {
    pname = "ha-automations";
    version = "0.1.0";
    src = "${inputs.self}/automations";
    nodejs = pkgs.nodejs_22;
    inherit (cfg) npmDepsHash;
  };
in {
  sops.secrets."ha-automations.env" = {
    format = "dotenv";
    restartUnits = ["ha-automations.service"];
  };

  systemd.services.ha-automations = {
    description = "Home Assistant automations daemon";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "hass-sync.service"];
    wants = ["network-online.target"];
    environment.HEALTH_PORT = toString cfg.healthPort;
    serviceConfig = {
      ExecStart = "${daemon}/bin/ha-automations";
      EnvironmentFile = config.sops.secrets."ha-automations.env".path; # HASS_URL, HASS_TOKEN
      DynamicUser = true;
      StateDirectory = "ha-automations";
      Restart = "always";
      RestartSec = 5;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      SystemCallFilter = ["@system-service"];
    };
  };
})
