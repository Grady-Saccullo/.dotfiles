{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "python";
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.python]))
  ];
  extraPackages = [
    pkgs.unstable.basedpyright
    pkgs.unstable.ruff
  ];
  initLua = ''
    addLspServer("basedpyright", {})
  '';
})
