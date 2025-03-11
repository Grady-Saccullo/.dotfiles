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
      rev = "a514379f5f89bf72955ed3bf5c1c31a40b8a1472";
      sha256 = "o5uD6shPkweuE+k/goBX42W3I2oojXVijfJC7L50sGU=";
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
