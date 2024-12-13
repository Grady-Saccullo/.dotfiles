{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.soundsource;
in {
  options = {
    applications.soundsource = {
      enable = mkEnableOption "SoundSource";
    };
  };
  config = lib.mkIf cfg.enable (
    if self.utils.isNotMachine "darwin"
    then throw "soundsource is only supported on darwin"
    else
      self.utils.mkHomeManagerUser {
        home.packages = [
          pkgs.unstable.soundsource
        ];
      }
  );
}
