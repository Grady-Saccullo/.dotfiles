{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "html";
  imports = [./htmx.nix];
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.html p.css]))
  ];

  extraLuaConfig = let
    templEnabled = config.applications.neovim.go.templ.enable;
    fileTypes = ["\"html\""] ++ lib.optionals templEnabled ["\"templ\""];
  in ''
    addLspServer("html", {
      filetypes = { ${lib.concatStringsSep ", " fileTypes} },
    })
    addLspServer("cssls", {})
  '';
})
