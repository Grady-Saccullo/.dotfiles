{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "jq";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "jq" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.jq = {
        enable = true;
        package = cfg.package;
      };
    })
