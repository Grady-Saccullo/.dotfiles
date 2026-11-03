{
  config,
  pkgs,
  utils,
  ...
}: let
  codelldb = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;
in
  utils.mkNeovimModule {
    inherit config pkgs;
    path = ["dap" "rust"];
  } ({lazy, ...}: {
    plugins = lazy {
      # nvim-dap owns the adapter table; this only fills it once dap is up.
      plugin = pkgs.vimUtils.buildVimPlugin {
        pname = "dap-rust-codelldb";
        version = "0";
        src = pkgs.writeTextDir "lua/dap-rust-codelldb/init.lua" ''
          return "${codelldb}/bin/codelldb"
        '';
      };
      event = ["User HmDapLoaded"];
      config = builtins.readFile ./dap-rust.lua;
    };
  })
