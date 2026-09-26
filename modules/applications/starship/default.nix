{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "starship";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "starship" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.starship = {
        enable = true;
        package = cfg.package;
        enableZshIntegration = config.applications.zsh.enable;
      };
    })
