{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "brave";
  inherit config;
  extraOptions = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.brave;
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.brave = {
        enable = true;
        package = cfg.package;
        extensions =
          [
            # Dark Reader
            {id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";}
            # YouTube Dislike
            {id = "gebbhagfogifgggkldgodflihgfeippi";}
          ]
          ++ config.common.browserExtensions.chromium;
      };
    })
