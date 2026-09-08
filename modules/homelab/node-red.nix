# Node-RED. State (flows, credentials, palette node_modules) lives in
# /var/lib/node-red and is carried over from the container as-is.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "node-red";
  inherit config;
  extraOptions = {
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    settingsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Custom settings.js (e.g. the old one with adminAuth). Null uses the
        package default. Point it at a file under /var/lib/node-red once the
        old data dir has been copied in.
      '';
    };
  };
} (cfg: {
  services.node-red = {
    enable = true;
    withNpmAndGcc = true; # palette installs from the editor still work
    userDir = "/var/lib/node-red";
    openFirewall = cfg.openFirewall;
    configFile = lib.mkIf (cfg.settingsFile != null) cfg.settingsFile;
  };

  systemd.services.node-red.after = ["home-assistant.service"];
})
