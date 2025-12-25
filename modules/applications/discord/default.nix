{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "discord";
  inherit config;
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.discord];
    })
