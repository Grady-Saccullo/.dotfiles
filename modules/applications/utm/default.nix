{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "utm";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.utm];
      };
      nixos = "utm is only supported on darwin";
      linux = "utm is only supported on darwin";
    })
