{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "charles-proxy";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "charles";
            greedy = true;
          }
        ];
      };
      nixos = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.charles];
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.charles];
      };
    })
