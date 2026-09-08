# Music Assistant: the HA-native multi-room audio layer. Sonos and Spotify
# providers match the existing integrations; the HA `music_assistant`
# integration then exposes players and media browsing.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "music-assistant";
  inherit config;
  extraOptions = {
    providers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["sonos" "spotify" "hass" "hass_players"];
    };
  };
} (cfg: {
  services.music-assistant = {
    enable = true;
    inherit (cfg) providers;
  };

  homelab.proxy.services.music = lib.mkDefault "http://127.0.0.1:8095";
  homelab.home-assistant.extraComponents = ["music_assistant"];

  # 8095 web/api, 8097 stream endpoint players pull from
  networking.firewall.allowedTCPPorts = [8095 8097];
})
