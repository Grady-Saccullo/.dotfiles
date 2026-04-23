{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "zoxide";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = config.applications.zsh.enable;
      };
    })
