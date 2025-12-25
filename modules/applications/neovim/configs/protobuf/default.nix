{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "protobuf";
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.proto]))
  ];

  extraPackages = [
    pkgs.unstable.protols
  ];

  extraLuaConfig = ''
    addLspServer("protols", {})
  '';
})
