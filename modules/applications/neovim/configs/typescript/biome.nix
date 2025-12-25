{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["typescript" "biome"];
} (_: {
  extraPackages = [
    pkgs.unstable.biome
  ];

  extraLuaConfig = ''
    addLspServer("biome", {})
  '';
})
