{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "android-studio";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "android-studio" {};
  };
} (cfg:
    utils.mkPlatformConfig {
      base = utils.mkHomeManagerUser {
        home.packages = [pkgs.android-tools pkgs.jdk17];
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
        home.packages = [cfg.package];
      };
      nixos = utils.mkHomeManagerUser {
        home.packages = [cfg.package];
      };
    })
