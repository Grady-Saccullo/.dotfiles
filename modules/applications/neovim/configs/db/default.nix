{
  config,
  lib,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;
  enable = allEnable config.applications.neovim [
    "enable"
    "db.enable"
  ];
in {
  imports = [./sql.nix];
  options = {
    applications.neovim.db = {
      enable = mkEnableOption "Database Integrations";
    };
  };

  config = mkIf enable (mkHomeManagerUser {
    # leaving for now as place holder
  });
}
