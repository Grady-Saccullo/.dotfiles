{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["dap" "go"];
} ({vimPlugins, ...}: {
  plugins = [
    {
      plugin = vimPlugins.nvim-dap-go;
      config = builtins.readFile ./dap-go.lua;
      type = "lua";
    }
  ];

  extraPackages = [
    pkgs.unstable.delve
  ];
})
