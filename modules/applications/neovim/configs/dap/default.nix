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
} ({
  vimPlugins,
  lazy,
  ...
}: {
  plugins = lazy {
    plugin = vimPlugins.nvim-dap;
    cmd = ["DapNew" "DapContinue" "DapToggleBreakpoint" "DapTerminate"];
    keys = [
      "<F5>"
      "<F10>"
      "<F11>"
      "<F12>"
      "<Leader>b"
      "<Leader>B"
      "<Leader>lp"
      "<Leader>dr"
      "<Leader>dl"
      "<Leader>df"
      "<Leader>Ds"
      {
        lhs = "<Leader>dh";
        mode = ["n" "v"];
      }
      {
        lhs = "<Leader>dp";
        mode = ["n" "v"];
      }
    ];
    after = [vimPlugins.nvim-nio vimPlugins.nvim-dap-ui vimPlugins.nvim-dap-virtual-text];
    # Adapters in other modules (dap.go) load on this event.
    config =
      builtins.readFile ./dap.lua
      + builtins.readFile ./dap-ui.lua
      + ''
        require("nvim-dap-virtual-text").setup({})
        vim.api.nvim_exec_autocmds("User", { pattern = "HmDapLoaded" })
      '';
  };
})
