{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.android-studio;
in {
  options = {
    applications.android-studio = {
      enable = mkEnableOption "Android Studio";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (self.utils.mkHomeManagerUser {
        home.packages =
          [pkgs.unstable.android-tools]
          ++ lib.optionals (self.utils.isNotMachine "darwin") [
            pkgs.unstable.android-studio
          ];
      })
      (lib.mkIf (self.utils.isMachine "darwin") {
        homebrew.casks = ["android-studio"];
      })
    ]
  );
}
