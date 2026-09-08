# Tailscale replaces the WireGuard container: no port forward, no public IP
# in a config file, devices already on the tailnet from the Macs. As a
# subnet router + exit node it exposes the LAN (and its DNS) to the tailnet;
# set "Override local DNS" -> this host's address in the admin console so
# ad blocking and *.home.arpa work remotely.
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
})
