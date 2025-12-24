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
        package = pkgs.unstable.git;
        settings = {
          user = {
            email = cfg.email;
            name = cfg.username;
          };
        };
        lfs = {
          enable = true;
        };
      };
      delta = {
        enable = true;
        enableGitIntegration = true;
      };
    };
  };
}
