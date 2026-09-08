# ntfy: self-hosted push notifications. HA's core `ntfy` integration and
# Alertmanager publish here; phones subscribe over https via the proxy or
# Tailscale. Access is deny-by-default; create users once with
#   sudo -u ntfy-sh ntfy user add --role=admin <name>
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "ntfy";
  inherit config;
} (cfg: let
  domain = config.homelab.domain;
in {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.${domain}";
      listen-http = "127.0.0.1:2586";
      behind-proxy = true;
      auth-file = "/var/lib/ntfy-sh/user.db";
      auth-default-access = "deny-all";
      cache-file = "/var/lib/ntfy-sh/cache.db";
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
    };
  };

  homelab.proxy.services.ntfy = lib.mkDefault "http://127.0.0.1:2586";
  homelab.home-assistant.extraComponents = ["ntfy"];
})
