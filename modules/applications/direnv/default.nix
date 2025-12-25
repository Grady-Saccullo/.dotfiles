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
      };
    })
