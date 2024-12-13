{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.bitwarden;
in {
  options = {
    applications.bitwarden = {
      enable = mkEnableOption "Bitwarden";

      browserExtension.enable = mkEnableOption "Bitwarden Browser Extension";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (self.utils.mkHomeManagerUser {
        home.packages =
          [
            # seems to be broken during one of the phases
            # pkgs.unstable.bitwarden-cli
          ]
          ++ lib.optionals (self.utils.isNotMachine "darwin") [
            pkgs.unstable.bitwarden-desktop
          ];
      })
      (lib.mkIf (self.utils.isMachine "darwin") {
        homebrew.masApps = {
          "Bitwarden" = 1352778147;
        };
      })
      (lib.mkIf cfg.browserExtension.enable {
        common.browserExtensions.chromium = [
          {id = "nngceckbapebfimnlniiiahkandclblb";}
        ];
      })
    ]
  );
}
