{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["dap" "typescript"];
} ({lazy, ...}: {
  plugins = lazy {
    # nvim-dap owns the adapter table; this only fills it once dap is up.
    plugin = pkgs.vimUtils.buildVimPlugin {
      pname = "dap-js-debug";
      version = "0";
      src = pkgs.writeTextDir "lua/dap-js-debug/init.lua" ''
        return "${pkgs.vscode-js-debug}/bin/js-debug"
      '';
    };
    event = ["User HmDapLoaded"];
    config = builtins.readFile ./dap-typescript.lua;
  };
})
