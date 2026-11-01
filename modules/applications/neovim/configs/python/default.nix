{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  testEnabled = config.applications.neovim.test.enable;
in
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
  } ({
    vimPlugins,
    lazy,
    ...
  }: {
    plugins =
      [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.python]))
      ]
      ++ lib.optionals testEnabled (lazy {
        plugin = vimPlugins.neotest-python.overrideAttrs (_: {
          dependencies = [];
          doCheck = false;
        });
        event = ["User HmNeotestAdapters"];
        config = ''
          addNeotestAdapter(function()
            return require("neotest-python")({ runner = "pytest", dap = { justMyCode = false } })
          end)
        '';
      });
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
