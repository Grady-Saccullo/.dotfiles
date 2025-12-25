{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [./go.nix];
  path = "dap";
} ({vimPlugins, ...}: {
  plugins = [
    {
      plugin = vimPlugins.nvim-dap;
      config = builtins.readFile ./dap.lua;
      type = "lua";
    }
    {
      plugin = vimPlugins.nvim-dap-ui;
      config = builtins.readFile ./dap-ui.lua;
      type = "lua";
    }
    vimPlugins.nvim-nio
  ];
})
