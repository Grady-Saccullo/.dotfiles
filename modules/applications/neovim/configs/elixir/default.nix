{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;
  enable = allEnable config.applications.neovim [
    "enable"
    "elixir.enable"
  ];
in {
  options = {
    applications.neovim.elixir = {
      enable = mkEnableOption "Elixir";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
    ls = pkgs.unstable.beam28Packages.elixir-ls;
    # ls = pkgs.unstable.beam28Packages.callPackage ({elixir-ls, elixir_1_19}: elixir-ls.override { elixir = elixir_1_19; }) {};
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.elixir p.eex p.heex p.erlang ]))
        (vimPlugins.elixir-tools-nvim)
      ];

      programs.neovim.extraLuaConfig = ''
        -- require("elixir").setup({
        --   elixirls = {
        --     cmd = "${ls}/bin/elixir-ls"
        --   }
        -- })
        addLspServer("elixirls", {
          cmd = { "${ls}/bin/elixir-ls" }
        })
      '';
    });
}
