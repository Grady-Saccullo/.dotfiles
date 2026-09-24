{
  config,
  pkgs,
  utils,
  ...
}: let
  ls = pkgs.beam28Packages.elixir-ls;
in
  utils.mkNeovimModule {
    inherit config pkgs;
    path = "elixir";
    extraConfig = _: {
      ai.lspServers.elixir = {
        command = "${ls}/bin/elixir-ls";
        extensionToLanguage = {
          ".ex" = "elixir";
          ".exs" = "elixir";
          ".eex" = "eex";
          ".heex" = "phoenix-heex";
        };
        description = "elixir language server for AI tools";
      };
    };
  } ({vimPlugins, ...}: {
    plugins = [
      (vimPlugins.nvim-treesitter.withPlugins (p: [p.elixir p.eex p.heex p.erlang]))
      (vimPlugins.elixir-tools-nvim)
    ];

    initLua = ''
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
