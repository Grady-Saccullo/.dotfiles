{
  utils,
  config,
  lib,
  ...
}:
utils.mkAppModule {
  path = "xcode";
  inherit config;
  extraOptions = {
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.apple.dt.Xcode";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
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
