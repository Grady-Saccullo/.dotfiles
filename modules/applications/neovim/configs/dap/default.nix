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
      {
        lhs = "<F5>";
        desc = "Debug: continue";
      }
      {
        lhs = "<F10>";
        desc = "Debug: step over";
      }
      {
        lhs = "<F11>";
        desc = "Debug: step into";
      }
      {
        lhs = "<F12>";
        desc = "Debug: step out";
      }
      {
        lhs = "<Leader>b";
        desc = "Debug: toggle [B]reakpoint";
      }
      {
        lhs = "<Leader>B";
        desc = "Debug: set [B]reakpoint";
      }
      {
        lhs = "<Leader>lp";
        desc = "Debug: [L]og [P]oint";
      }
      {
        lhs = "<Leader>dr";
        desc = "[D]ebug [R]EPL";
      }
      {
        lhs = "<Leader>dl";
        desc = "[D]ebug run [L]ast";
      }
      {
        lhs = "<Leader>dh";
        desc = "[D]ebug [H]over";
        mode = ["n" "v"];
      }
      {
        lhs = "<Leader>dp";
        desc = "[D]ebug [P]review";
        mode = ["n" "v"];
      }
      {
        lhs = "<Leader>df";
        desc = "[D]ebug [F]rames";
      }
      {
        lhs = "<Leader>Ds";
        desc = "[D]ebug [S]copes";
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
