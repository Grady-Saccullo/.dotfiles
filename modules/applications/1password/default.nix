{
  pkgs,
  config,
  utils,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications._1password;
in {
  options = {
    applications._1password = {
      enable = mkEnableOption "1Password";

      browserExtension.enable = mkEnableOption "1Password Browser Extension";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin = {
          homebrew.casks = [
            {
              name = "1password";
              greedy = true;
            }
          ];
          programs._1password = {
            enable = true;
            package = pkgs.unstable._1password-cli;
          };
        };
        linux = utils.mkHomeManagerUser {
          home.packages = [
            pkgs.unstable._1password-gui
            pkgs.unstable._1password-cli
          ];
        };
        nixos = utils.mkHomeManagerUser {
          home.packages = [
            pkgs.unstable._1password-gui
            pkgs.unstable._1password-cli
          ];
        };
      })
      (lib.mkIf cfg.browserExtension.enable {
        common.browserExtensions.chromium = [
          {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";}
        ];
      })
    ]
  );
}
