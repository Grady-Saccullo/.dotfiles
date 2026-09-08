# Node-RED. State (flows, credentials, palette node_modules) lives in
# /var/lib/node-red and is carried over from the container as-is.
#
# settings.js is rendered by sops-nix: the editor is bound to loopback
# (reach it through the proxy), protected by adminAuth, and credentialSecret
# is pinned so the encrypted flows_cred.json stays readable even if the
# runtime config file is lost. Flows hold a long-lived HA token, so an
# unauthenticated editor would hand out control of the house.
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
    port = lib.mkOption {
      type = lib.types.port;
      default = 1880;
    };
  };
} (cfg: {
  # bcrypt hash: `node-red admin hash-pw` or `htpasswd -B -n -b x 'pw' | cut -d: -f2`
  sops.secrets."node-red/admin_password_hash" = {};
  # Must equal `_credentialSecret` from the old data dir's .config.runtime.json
  sops.secrets."node-red/credential_secret" = {};

  sops.templates."node-red-settings.js" = {
    owner = "node-red";
    mode = "0400";
    restartUnits = ["node-red.service"];
    content = ''
      module.exports = {
        flowFile: "flows.json",
        flowFilePretty: true,
        credentialSecret: "${config.sops.placeholder."node-red/credential_secret"}",
        uiHost: "127.0.0.1",
        uiPort: ${toString cfg.port},
        adminAuth: {
          type: "credentials",
          users: [
            {
              username: "admin",
              password: "${config.sops.placeholder."node-red/admin_password_hash"}",
              permissions: "*",
            },
          ],
        },
        diagnostics: { enabled: true, ui: true },
        runtimeState: { enabled: false, ui: false },
        logging: { console: { level: "info", metrics: false, audit: false } },
        editorTheme: { projects: { enabled: false } },
        functionExternalModules: true,
        functionGlobalContext: {},
        exportGlobalContextKeys: false,
      };
    '';
  };

  services.node-red = {
    enable = true;
    withNpmAndGcc = true; # palette installs from the editor still work
    userDir = "/var/lib/node-red";
    inherit (cfg) port;
    configFile = config.sops.templates."node-red-settings.js".path;
  };

  systemd.services.node-red.after = ["home-assistant.service"];
  homelab.proxy.services.nodered = lib.mkDefault "http://127.0.0.1:${toString cfg.port}";
})
