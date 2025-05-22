{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;

  sqls-nvim = pkgs.unstable.vimUtils.buildVimPlugin {
    name = "sqls.nvim";
    src = pkgs.unstable.fetchFromGitHub {
      owner = "nanotee";
      repo = "sqls.nvim";
      rev = "d1bc5421ef3e8edc5101e37edbb7de6639207a09";
      sha256 = "bQKO5Kq4Jc8v7d6OSkkzjqYHzt8c5C71xzHHABErlsg=";
    };
  };

  enable = allEnable config.applications.neovim [
    "enable"
    "db.enable"
    "db.sql.enable"
  ];
in {
  options = {
    applications.neovim.db.sql = {
      enable = mkEnableOption "SQL Database";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.sql]))
        sqls-nvim
      ];

      programs.neovim.extraPackages = [
        pkgs.unstable.sqls
      ];

      programs.neovim.extraLuaConfig = ''
        addLspServer("sqls", {
          on_attach = function(client, bufnr)
            require('sqls').on_attach(client, bufnr)
          end
        })
      '';
    });
}
