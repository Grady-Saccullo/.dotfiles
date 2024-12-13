{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (inputs) self;
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
  config = self.utils.mkHomeManagerUser {
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
