{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "jq";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.jq.enable = true;
    })
