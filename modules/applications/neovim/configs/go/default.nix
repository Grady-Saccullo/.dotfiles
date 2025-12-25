{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [./templ.nix];
  path = "go";
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [
      p.go
      p.gomod
      p.gosum
      p.gowork
    ]))
    (vimPlugins.go-nvim)
  ];

  extraPackages = [
    pkgs.unstable.gopls
  ];

  extraLuaConfig = ''
    require('go').setup()
    ${builtins.readFile ./go-lsp.lua}
  '';
})
