{
  utils,
  config,
  lib,
  pkgs,
  me,
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
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/Applications/Home Manager Apps/Brave Browser.app";
      description = "Path to the Brave Browser application";
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
