{
  utils,
  config,
  pkgs,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["go" "templ"];
  extraConfig = _: {
    ai.lspServers.templ = {
      command = "${pkgs.templ}/bin/templ";
      args = ["lsp"];
      extensionToLanguage = {
        ".templ" = "templ";
      };
      description = "templ language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.templ]))
  ];

  extraPackages = [
    pkgs.templ
  ];

  initLua = ''
    ${builtins.readFile ./go-templ-lsp.lua}
  '';
})
