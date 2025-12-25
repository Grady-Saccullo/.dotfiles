{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "devenv";
  inherit config;
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.devenv];
    })
