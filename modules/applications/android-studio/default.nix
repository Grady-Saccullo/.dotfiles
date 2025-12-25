{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "android-studio";
  inherit config;
} (_:
    utils.mkPlatformConfig {
      base = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.android-tools pkgs.jdk17];
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
    })
