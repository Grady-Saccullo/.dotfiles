{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "direnv";
  inherit config;
  default = true;
  extraOptions = {
    package = lib.mkPackageOption pkgs "direnv" {};
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.direnv = {
        enable = true;
        package = cfg.package;
        enableZshIntegration = config.applications.zsh.enable;
        nix-direnv.enable = true;
        # Suppress the noisy `direnv: export +VAR +VAR ...` env-diff dump on
        # every shell entry. Keeps the concise `direnv: loading` status line.
        config.global.hide_env_diff = true;
      };
    })
