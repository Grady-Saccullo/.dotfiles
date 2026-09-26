{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "zoxide";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "zoxide" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.zoxide = {
        enable = true;
        package = cfg.package;
        enableZshIntegration = config.applications.zsh.enable;
      };
    })
