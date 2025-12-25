{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "ocaml";
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.unstable.ocamlPackages.lsp
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.ocaml]))
  ];

  extraLuaConfig = ''
    addLspServer("ocamllsp", {})
  '';
})
