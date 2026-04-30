{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "direnv";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.direnv = {
        enable = true;
        enableZshIntegration = config.applications.zsh.enable;
        nix-direnv.enable = true;
        # Suppress the noisy `direnv: export +VAR +VAR ...` env-diff dump on
        # every shell entry. Keeps the concise `direnv: loading` status line.
        config.global.hide_env_diff = true;
      };
    })
