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
    pkgs.unstable.htmx-lsp
  ];

  extraLuaConfig = let
    templEnabled = config.applications.neovim.go.templ.enable;
    fileTypes = ["\"html\""] ++ lib.optionals templEnabled ["\"templ\""];
  in ''
    addLspServer("htmx", {
      filetypes = { ${lib.concatStringsSep ", " fileTypes} },
    })
  '';
})
