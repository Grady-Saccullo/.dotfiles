{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "zig";
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.unstable.zls
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.zig]))
    vimPlugins.zig-vim
  ];

  extraLuaConfig = ''
    addLspServer("zls", {
        enable_build_on_save = true
    })
  '';
})
