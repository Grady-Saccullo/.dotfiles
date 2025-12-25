{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["db" "sql"];
} ({
  vimPlugins,
  cfg,
}: let
  sqls-nvim = pkgs.unstable.vimUtils.buildVimPlugin {
    name = "sqls.nvim";
    src = pkgs.unstable.fetchFromGitHub {
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
    pkgs.unstable.sqls
  ];

  extraLuaConfig = ''
    addLspServer("sqls", {
      on_attach = function(client, bufnr)
        require('sqls').on_attach(client, bufnr)
      end
    })
  '';
})
