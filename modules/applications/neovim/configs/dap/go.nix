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

  # dlv compiles the debuggee with the `go` on PATH.
  extraPackages = [
    pkgs.delve
    pkgs.delve.go
  ];
})
