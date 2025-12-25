{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [./sql.nix];
  path = "db";
} (_: {})
