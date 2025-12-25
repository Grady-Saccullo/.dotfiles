{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "zoom";
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.zoom-us];
    })
