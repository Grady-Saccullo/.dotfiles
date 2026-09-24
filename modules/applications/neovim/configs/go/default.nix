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
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [
      p.go
      p.gomod
      p.gosum
      p.gowork
    ]))
    (vimPlugins.go-nvim)
  ];

  extraPackages = [
    pkgs.gopls
  ];

  initLua = ''
    require('go').setup()
    ${builtins.readFile ./go-lsp.lua}
  '';
})
