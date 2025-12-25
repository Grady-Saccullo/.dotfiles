{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["go" "templ"];
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.templ]))
  ];

  extraPackages = [
    pkgs.unstable.templ
  ];

  extraLuaConfig = ''
    ${builtins.readFile ./go-templ-lsp.lua}
  '';
})
