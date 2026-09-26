{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "yazi";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "yazi" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.yazi = {
        enable = true;
        package = cfg.package;
        enableZshIntegration = config.applications.zsh.enable;
        shellWrapperName = "y";
      };
    })
