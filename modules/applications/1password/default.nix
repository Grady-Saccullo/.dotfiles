{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self;
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
      (self.utils.mkHomeManagerUser {
        home.packages = [
          pkgs.unstable._1password-gui
          pkgs.unstable._1password-cli
        ];
      })
      (lib.mkIf cfg.browserExtension.enable {
        common.browserExtensions.chromium = [
          {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";}
        ];
      })
    ]
  );
}
