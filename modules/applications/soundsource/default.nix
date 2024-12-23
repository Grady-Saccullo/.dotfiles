{
  config,
  lib,
  utils,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.soundsource;
in {
  options = {
    applications.soundsource = {
      enable = mkEnableOption "SoundSource";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = utils.mkHomeManagerUser {
      home.packages = [
        pkgs.unstable.soundsource
      ];
    };
    nixos = "soundsource is only supported on darwin";
    linux = "soundsource is only supported on darwin";
  });
}
