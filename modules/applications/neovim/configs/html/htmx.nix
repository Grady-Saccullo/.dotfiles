# htmx-lsp is intentionally NOT contributed to ai.lspServers: it would claim
# `.html`, and Claude Code only starts the first server registered per
# extension, so it would shadow (or be shadowed by) the html server.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["html" "htmx"];
} (_: {
  extraPackages = [
    pkgs.htmx-lsp
  ];

  initLua = let
    templEnabled = config.applications.neovim.go.templ.enable;
    fileTypes = ["\"html\""] ++ lib.optionals templEnabled ["\"templ\""];
  in ''
    addLspServer("htmx", {
      filetypes = { ${lib.concatStringsSep ", " fileTypes} },
    })
  '';
})
