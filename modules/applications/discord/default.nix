{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "discord";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "discord";
            greedy = true;
          }
        ];
      };
      nixos = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.discord];
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.discord];
      };
    })
