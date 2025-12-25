{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "xcode";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.masApps = {
          "Xcode" = 497799835;
        };
      };
      nixos = "xcode is only supported on darwin";
      linux = "xcode is only supported on darwin";
    })
