{
  pkgs,
  utils,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.hoppscotch;
in {
  options = {
    applications.hoppscotch = {
      enable = mkEnableOption "Hoppscotch";
    };
  };

  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [pkgs.unstable.hoppscotch];
  });
}
