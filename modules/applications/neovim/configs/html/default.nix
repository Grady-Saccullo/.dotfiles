{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  # html / cssls binaries; the package itself is installed by the root neovim
  # module's extraPackages.
  ls = pkgs.vscode-langservers-extracted;
in
  utils.mkNeovimModule {
    inherit config pkgs;
    path = "html";
    imports = [./htmx.nix];
    # `.templ` is deliberately left to the templ server: Claude Code starts
    # only the first server registered for an extension.
    extraConfig = _: {
      ai.lspServers = {
        html = {
          command = "${ls}/bin/vscode-html-language-server";
          args = ["--stdio"];
          extensionToLanguage = {
            ".html" = "html";
            ".htm" = "html";
          };
          description = "html language server for AI tools";
        };
        css = {
          command = "${ls}/bin/vscode-css-language-server";
          args = ["--stdio"];
          extensionToLanguage = {
            ".css" = "css";
            ".scss" = "scss";
            ".less" = "less";
          };
          description = "css language server for AI tools";
        };
      };
    };
  } ({vimPlugins, ...}: {
    plugins = [
      (vimPlugins.nvim-treesitter.withPlugins (p: [p.html p.css]))
    ];

    initLua = let
      templEnabled = config.applications.neovim.go.templ.enable;
      fileTypes = ["\"html\""] ++ lib.optionals templEnabled ["\"templ\""];
    in ''
      addLspServer("html", {
        filetypes = { ${lib.concatStringsSep ", " fileTypes} },
      })
      addLspServer("cssls", {})
    '';
  })
