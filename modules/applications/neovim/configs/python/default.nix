{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "python";
  extraConfig = _: {
    ai.lspServers.python = {
      command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
      args = ["--stdio"];
      extensionToLanguage = {
        ".py" = "python";
        ".pyi" = "python";
      };
      description = "python language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.python]))
  ];
  extraPackages = [
    pkgs.basedpyright
    pkgs.ruff
  ];
  initLua = ''
    addLspServer("basedpyright", {})
  '';
})
