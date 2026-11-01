{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "test";
} ({
  vimPlugins,
  lazy,
  ...
}: {
  plugins = lazy {
    plugin = vimPlugins.neotest;
    before = [vimPlugins.nvim-nio];
    # Language modules register adapters on this event; they must be on the runtimepath before setup.
    beforeConfig = ''
      vim.api.nvim_exec_autocmds("User", { pattern = "HmNeotestAdapters" })
    '';
    keys = [
      {
        lhs = "<leader>tt";
        desc = "[T]est nearest";
      }
      {
        lhs = "<leader>tT";
        desc = "[T]est file";
      }
      {
        lhs = "<leader>ta";
        desc = "[T]est [A]ll (suite)";
      }
      {
        lhs = "<leader>td";
        desc = "[T]est [D]ebug nearest";
      }
      {
        lhs = "<leader>ts";
        desc = "[T]est [S]ummary";
      }
      {
        lhs = "<leader>to";
        desc = "[T]est [O]utput";
      }
      {
        lhs = "<leader>tO";
        desc = "[T]est [O]utput panel";
      }
      {
        lhs = "<leader>tw";
        desc = "[T]est [W]atch file";
      }
      {
        lhs = "<leader>tx";
        desc = "[T]est stop";
      }
      {
        lhs = "]t";
        desc = "Next failed test";
      }
      {
        lhs = "[t";
        desc = "Previous failed test";
      }
    ];
    config = builtins.readFile ./neotest.lua;
  };
})
