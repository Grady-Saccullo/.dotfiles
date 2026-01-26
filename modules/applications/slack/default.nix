{
  utils,
  config,
  lib,
  pkgs,
  me,
  ...
}:
utils.mkAppModule {
  path = "slack";
  inherit config;
  extraOptions = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.slack;
    };
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/Applications/Home Manager Apps/Slack.app";
      description = "Path to the Slack application";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [cfg.package];
    })
