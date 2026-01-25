{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "rust";
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.unstable.rust-analyzer
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.rust]))
  ];

  initLua = ''
    addLspServer("rust_analyzer", {
     	settings = {
     		diagnostics = {
     			enable = true,
     		},
     	},
     })
  '';
})
