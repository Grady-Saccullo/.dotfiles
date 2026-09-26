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
    package = lib.mkPackageOption pkgs "brave" {};
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/Applications/Home Manager Apps/Brave Browser.app";
      description = "Path to the Brave Browser application";
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.brave.Browser";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
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
          ++ lib.mapAttrsToList (_: e: {inherit (e) id;})
          (utils.enabled config.browser.extensions.chromium);
      };
    })
