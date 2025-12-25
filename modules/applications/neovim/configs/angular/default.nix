{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "angular";
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.angular]))
  ];
})
