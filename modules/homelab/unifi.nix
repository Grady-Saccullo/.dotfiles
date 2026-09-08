# UniFi network controller, self-hosted instead of a cloud key. Unfree
# (UniFi + MongoDB). Reach it at https://<host>:8443 (self-signed).
{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkHomelabModule {
  path = "unifi";
  inherit config;
} (cfg: {
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb-7_0;
    openFirewall = true;
  };
})
