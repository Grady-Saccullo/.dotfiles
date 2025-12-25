{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "elixir";
} ({vimPlugins, ...}: let
  ls = pkgs.unstable.beam28Packages.elixir-ls;
in {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.elixir p.eex p.heex p.erlang]))
    (vimPlugins.elixir-tools-nvim)
  ];

  extraLuaConfig = ''
    -- require("elixir").setup({
    --   elixirls = {
    --     cmd = "${ls}/bin/elixir-ls"
    --   }
    -- })
    addLspServer("elixirls", {
      cmd = { "${ls}/bin/elixir-ls" }
    })
  '';
})
