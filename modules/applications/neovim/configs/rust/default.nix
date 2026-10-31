{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "rust";
  extraConfig = _: {
    ai.lspServers.rust = {
      command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      extensionToLanguage = {
        ".rs" = "rust";
      };
      description = "rust language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  # rust-analyzer runs `cargo metadata` in Cargo projects; its wrapper already sets RUST_SRC_PATH.
  extraPackages = [
    pkgs.rust-analyzer
    pkgs.cargo
    pkgs.rustc
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
