{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["dap" "go"];
} ({
  vimPlugins,
  lazy,
  ...
}: {
  plugins = lazy {
    plugin = vimPlugins.nvim-dap-go;
    event = ["User HmDapLoaded"];
    config = builtins.readFile ./dap-go.lua;
  };

  # dlv compiles the debuggee with the `go` on PATH.
  extraPackages = [
    pkgs.delve
    pkgs.delve.go
  ];
})
