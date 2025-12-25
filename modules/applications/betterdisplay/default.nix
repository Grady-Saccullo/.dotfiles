{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "betterdisplay";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "betterdisplay";
            greedy = true;
          }
        ];
      };
      nixos = "betterdisplay is only supported on darwin";
      linux = "betterdisplay is only supported on darwin";
    })
