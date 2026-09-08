# Jellyfin media server with Intel QuickSync transcoding. The media role.
# Libraries live wherever the media disks are mounted (ZFS on the media
# box); point them at it from the Jellyfin UI.
{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkHomelabModule {
  path = "jellyfin";
  inherit config;
} (cfg: {
  services.jellyfin = {
    enable = true;
    openFirewall = true; # DLNA / client discovery on the LAN
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # VAAPI for Broadwell+ iGPUs
      vpl-gpu-rt # oneVPL / QSV
    ];
  };
  users.users.jellyfin.extraGroups = ["video" "render"];

  homelab.proxy.services.jellyfin = lib.mkDefault "http://127.0.0.1:8096";
})
