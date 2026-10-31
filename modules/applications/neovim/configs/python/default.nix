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
  # basedpyright invokes `python` to resolve installed packages when no venv is configured.
  extraPackages = [
    pkgs.basedpyright
    pkgs.ruff
    pkgs.python3
  ];
  initLua = ''
    addLspServer("basedpyright", {})
  '';
})
