{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkAppModule {
  path = "hoppscotch";
  inherit config;
} (cfg:
    utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.hoppscotch];
    })
