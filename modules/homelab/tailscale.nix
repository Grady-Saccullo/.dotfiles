# Tailscale replaces the WireGuard container: no port forward, no public IP
# in a config file, devices already on the tailnet from the Macs. As a
# subnet router it exposes the Infra and IoT VLANs to the tailnet (no exit
# node: it drains phone batteries and the family uses Nabu Casa for HA).
# In the admin console: approve the routes, set the tailnet nameserver to
# the DNS VIP restricted to the home domain, enable SSH check mode.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "tailscale";
  inherit config;
  extraOptions = {
    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    exitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
} (cfg: {
  sops.secrets."tailscale/auth_key" = {};

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
    # `tailscale up` only runs when the node needs to log in, so anything in
    # extraUpFlags is frozen at first join. `tailscale set` runs on every
    # start; routes/exit node/ssh live there so config changes take effect.
    extraSetFlags =
      ["--ssh"]
      ++ lib.optional (cfg.advertiseRoutes != [])
      "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
      ++ lib.optional cfg.exitNode "--advertise-exit-node";
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];
  networking.firewall.checkReversePath = "loose";
})
