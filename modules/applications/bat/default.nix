{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "bat";
  inherit config;
  default = true;
} (cfg:
    utils.mkHomeManagerUser {
      programs.bat.enable = true;
    })
