{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "btop";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.btop.enable = true;
    })
