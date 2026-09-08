# Local voice for HA Assist: faster-whisper (speech to text), piper (text to
# speech) and openWakeWord, all over the Wyoming protocol on loopback. A
# micro PC CPU handles the small models fine. Replaces google_translate TTS
# and keeps audio in the house.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "voice";
  inherit config;
  extraOptions = {
    whisperModel = lib.mkOption {
      type = lib.types.str;
      default = "base-int8";
      description = "tiny-int8 is fastest, small-int8 is noticeably better on a modern CPU.";
    };
    piperVoice = lib.mkOption {
      type = lib.types.str;
      default = "en_US-lessac-medium";
    };
  };
} (cfg: {
  services.wyoming = {
    faster-whisper.servers.default = {
      enable = true;
      model = cfg.whisperModel;
      language = "en";
      uri = "tcp://127.0.0.1:10300";
      device = "cpu";
    };
    piper.servers.default = {
      enable = true;
      voice = cfg.piperVoice;
      uri = "tcp://127.0.0.1:10200";
    };
    openwakeword = {
      enable = true;
      uri = "tcp://127.0.0.1:10400";
      preloadModels = ["ok_nabu"];
    };
  };

  homelab.home-assistant.extraComponents = ["wyoming"];
})
