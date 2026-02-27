{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [./rest.nix ./kulala.nix];
  path = "http";
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.http]))
  ];
})
