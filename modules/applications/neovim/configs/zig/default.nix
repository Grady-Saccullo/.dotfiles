{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "zig";
  extraConfig = _: {
    ai.lspServers.zig = {
      command = "${pkgs.zls}/bin/zls";
      extensionToLanguage = {
        ".zig" = "zig";
        ".zon" = "zig";
      };
      description = "zig language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.zls
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.zig]))
    vimPlugins.zig-vim
  ];

  initLua = ''
    addLspServer("zls", {
        enable_build_on_save = true
    })
  '';
})
