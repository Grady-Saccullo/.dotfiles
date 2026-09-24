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
  cfg,
}: let
  sqls-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "sqls.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "nanotee";
      repo = "sqls.nvim";
      rev = "d1bc5421ef3e8edc5101e37edbb7de6639207a09";
      sha256 = "bQKO5Kq4Jc8v7d6OSkkzjqYHzt8c5C71xzHHABErlsg=";
    };
  };
in {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.sql]))
    sqls-nvim
  ];

  extraPackages = [
    pkgs.sqls
  ];

  initLua = ''
    addLspServer("sqls", {
      on_attach = function(client, bufnr)
        require('sqls').on_attach(client, bufnr)
      end
    })
  '';
})
