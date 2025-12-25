{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "bettersnaptool";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.masApps = {
          "BetterSnapTool" = 417375580;
        };
      };
      nixos = "bettersnaptool is only supported on darwin";
      linux = "bettersnaptool is only supported on darwin";
    })
