{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "yazi";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.yazi = {
        enable = true;
        enableZshIntegration = config.applications.zsh.enable;
        shellWrapperName = "y";
      };
    })
