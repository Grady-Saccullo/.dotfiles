{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "starship";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.starship = {
        enable = true;
        enableZshIntegration = config.applications.zsh.enable;
      };
    })
