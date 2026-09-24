{
  config,
  pkgs,
  utils,
  ...
}: let
  # ocamlPackages.lsp is only the protocol library; ocaml-lsp ships the
  # `ocamllsp` server binary.
  ls = pkgs.ocamlPackages.ocaml-lsp;
in
  utils.mkNeovimModule {
    inherit config pkgs;
    path = "ocaml";
    extraConfig = _: {
      ai.lspServers.ocaml = {
        command = "${ls}/bin/ocamllsp";
        extensionToLanguage = {
          ".ml" = "ocaml";
          ".mli" = "ocaml.interface";
        };
        description = "ocaml language server for AI tools";
      };
    };
  } ({vimPlugins, ...}: {
    extraPackages = [
      ls
    ];

    plugins = [
      (vimPlugins.nvim-treesitter.withPlugins (p: [p.ocaml]))
    ];

    initLua = ''
      addLspServer("ocamllsp", {})
    '';
  })
