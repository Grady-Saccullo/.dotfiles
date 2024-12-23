{
  pkgs,
  config,
  utils,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.bitwarden;
in {
  options = {
    applications.bitwarden = {
      enable = mkEnableOption "Bitwarden";
      browserExtension.enable = mkEnableOption "Bitwarden Browser Extension";
    };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [
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
  ]);
}
