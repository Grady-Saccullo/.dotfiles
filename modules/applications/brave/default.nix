{
  utils,
  config,
  lib,
  ...
}:
utils.mkAppModule {
  path = "brave";
  inherit config;
  imports = [
    (lib.mkRemovedOptionModule ["applications" "brave" "package"] "brave left nixpkgs on 2026-11-03; the module installs the brave-browser Homebrew cask instead.")
  ];
  extraOptions = {
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Applications/Brave Browser.app";
      description = "Path to the Brave Browser application";
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.brave.Browser";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (_:
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin = {
          homebrew.casks = [
            {
              name = "brave-browser";
              greedy = true;
            }
          ];
        };
        nixos = "brave is only supported on darwin: nixpkgs removed the package on 2026-11-03";
        linux = "brave is only supported on darwin: nixpkgs removed the package on 2026-11-03";
      })
      (utils.mkHomeManagerUser {
        programs.brave = {
          enable = true;
          # nixpkgs dropped brave (2026-11-03, no committer to merge its security fixes); the cask ships
          # the same official .dmg and self-updates, and without a package home-manager only writes extensions.
          package = null;
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
    ])
