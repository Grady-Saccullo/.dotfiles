{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "soundsource";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = utils.mkHomeManagerUser {
        home.packages = [pkgs.unstable.soundsource];
      };
      nixos = "soundsource is only supported on darwin";
      linux = "soundsource is only supported on darwin";
    })
