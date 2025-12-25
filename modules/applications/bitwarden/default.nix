{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "bitwarden";
  extraOptions = {
    browserExtension.enable = lib.mkEnableOption "Bitwarden Browser Extension";
  };
} (cfg:
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin = {
          homebrew.masApps = {
            "Bitwarden" = 1352778147;
          };
        };
        nixos = utils.mkHomeManagerUser {
          home.packages = [pkgs.unstable.bitwarden-desktop];
        };
        linux = utils.mkHomeManagerUser {
          home.packages = [pkgs.unstable.bitwarden-desktop];
        };
      })
      (lib.mkIf cfg.browserExtension.enable {
        common.browserExtensions.chromium = [
          {id = "nngceckbapebfimnlniiiahkandclblb";}
        ];
      })
    ])
