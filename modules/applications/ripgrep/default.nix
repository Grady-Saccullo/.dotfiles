{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "ripgrep";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.ripgrep.enable = true;
    })
