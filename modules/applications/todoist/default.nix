{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "todoist";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.casks = [
          {
            name = "todoist";
            greedy = true;
          }
        ];
      };
      nixos = "todoist is only supported on darwin";
      linux = "todoist is only supported on darwin";
    })
