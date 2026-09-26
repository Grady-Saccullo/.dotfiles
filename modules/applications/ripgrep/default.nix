{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "ripgrep";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "ripgrep" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.ripgrep = {
        enable = true;
        package = cfg.package;
      };
    })
