{
  utils,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.applications.git;
in {
  options = {
    applications.git = {
      username = mkOption {
        type = types.str;
        default = "Grady Saccullo";
      };
      email = mkOption {
        type = types.str;
        default = "gradys.dev@gmail.com";
      };
    };
  };
  config = utils.mkHomeManagerUser {
    home.packages = [pkgs.unstable.git-filter-repo];
    programs = {
      git = {
        enable = true;
        package = pkgs.unstable.gitFull;
        userName = cfg.username;
        userEmail = cfg.email;
        lfs = {
          enable = true;
        };
        delta = {
          enable = true;
        };
      };
    };
  };
}
