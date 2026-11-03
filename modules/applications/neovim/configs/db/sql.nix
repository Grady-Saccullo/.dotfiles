{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["db" "sql"];
  extraConfig = _: {
    ai.lspServers.sql = {
      command = "${pkgs.sqls}/bin/sqls";
      extensionToLanguage = {
        ".sql" = "sql";
      };
      description = "sql language server for AI tools";
    };
  };
} ({
  vimPlugins,
  lazy,
  ...
}: {
  plugins =
    [
      (vimPlugins.nvim-treesitter.withPlugins (p: [p.sql]))
    ]
    ++ lazy {
      plugin = vimPlugins.vim-dadbod-ui;
      cmd = ["DBUI" "DBUIToggle" "DBUIAddConnection" "DBUIFindBuffer"];
      ft = ["sql" "mysql" "plsql"];
      keys = [
        {
          lhs = "<leader>oo";
          desc = "Database: t[O]ggle DBUI";
        }
        {
          lhs = "<leader>of";
          desc = "Database: [F]ind buffer";
        }
      ];
      before = [vimPlugins.vim-dadbod];
      after = [vimPlugins.vim-dadbod-completion];
      beforeConfig = builtins.readFile ./dadbod-before.lua;
      config = builtins.readFile ./dadbod.lua;
    };

  # dadbod shells out to the CLI client; psql comes from the repo's devshell, which is also where
  # $DATABASE_URL comes from. conform's sqlfluff only runs where a .sqlfluff file sets the dialect.
  extraPackages = [
    pkgs.sqlite
    pkgs.sqlfluff
  ];
})
