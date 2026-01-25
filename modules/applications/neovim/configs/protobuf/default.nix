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

  initLua = ''
    addLspServer("protols", {
      -- Add support for monorepo where protols.toml may not be in the root of the repo
      root_markers = { ".protols.toml", "protols.toml", ".git" }
    })
  '';
})
