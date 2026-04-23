{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "tailscale";
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "tailscale-app";
            greedy = true;
          }
        ];
      };
      nixos = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.tailscale];
      };
      linux = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.tailscale];
      };
    })
