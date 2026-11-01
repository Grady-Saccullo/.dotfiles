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
    path = "zig";
    extraConfig = _: {
      ai.lspServers.zig = {
        command = "${pkgs.zls}/bin/zls";
        extensionToLanguage = {
          ".zig" = "zig";
          ".zon" = "zig";
        };
        description = "zig language server for AI tools";
      };
    };
  } ({
    vimPlugins,
    lazy,
    ...
  }: {
    # zls looks zig up in PATH; nixpkgs keeps the two on the same minor.
    extraPackages = [
      pkgs.zls
      pkgs.zig
    ];

    plugins =
      [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.zig]))
      ]
      ++ lazy {
        plugin = vimPlugins.zig-vim;
        ft = ["zig"];
      }
      ++ lib.optionals testEnabled (lazy {
        plugin = vimPlugins.neotest-zig.overrideAttrs (_: {
          dependencies = [];
          doCheck = false;
        });
        event = ["User HmNeotestAdapters"];
        config = ''
          addNeotestAdapter(function()
            return require("neotest-zig")({})
          end)
        '';
      });

    initLua = ''
      addLspServer("zls", {
          enable_build_on_save = true
      })
    '';
  })
