{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.utm;
in {
  options = {
    applications.utm = {
      enable = mkEnableOption "UTM";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.utm];
    };
    nixos = "utm is only supported on darwin";
    linux = "utm is only supported on darwin";
  });
}
