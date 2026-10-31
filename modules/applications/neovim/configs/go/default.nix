{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [./templ.nix];
  path = "go";
  extraConfig = _: {
    ai.lspServers.go = {
      command = "${pkgs.gopls}/bin/gopls";
      args = ["serve"];
      extensionToLanguage = {
        ".go" = "go";
        ".mod" = "go.mod";
        ".sum" = "go.sum";
        ".work" = "go.work";
      };
      description = "go language server for AI tools";
    };
  };
} ({
  vimPlugins,
  lazy,
  ...
}: {
  plugins =
    [
      (vimPlugins.nvim-treesitter.withPlugins (p: [
        p.go
        p.gomod
        p.gosum
        p.gowork
      ]))
    ]
    ++ lazy {
      plugin = vimPlugins.go-nvim;
      ft = ["go" "gomod" "gosum" "gowork" "gotmpl"];
      before = [vimPlugins.guihua-lua];
      config = "require('go').setup()";
    };

  # gopls.go is the toolchain gopls was built with; a repo shell's go still wins on PATH.
  extraPackages = [
    pkgs.gopls
    pkgs.gopls.go
  ];

  initLua = builtins.readFile ./go-lsp.lua;
})
