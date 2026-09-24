{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "halloy";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "halloy";
            greedy = true;
          }
        ];
      };
      nixos = utils.mkHomeManagerUser {
        home.packages = [pkgs.halloy];
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [pkgs.halloy];
      };
    })
