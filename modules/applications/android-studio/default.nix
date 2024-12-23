{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.android-studio;
in {
  options = {
    applications.android-studio = {
      enable = mkEnableOption "Android Studio";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    base = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.android-tools];
    };
    darwin = {
      homebrew.casks = [
        {
          name = "android-studio";
          greedy = true;
        }
      ];
    };
    linux = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.android-studio];
    };
    nixos = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.android-studio];
    };
  });
}
