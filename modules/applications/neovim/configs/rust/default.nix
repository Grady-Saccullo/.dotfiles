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
    path = "rust";
    extraConfig = _: {
      ai.lspServers.rust = {
        command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        extensionToLanguage = {
          ".rs" = "rust";
        };
        description = "rust language server for AI tools";
      };
    };
  } ({
    vimPlugins,
    lazy,
    ...
  }: {
    # rust-analyzer runs `cargo metadata` in Cargo projects; its wrapper already sets RUST_SRC_PATH.
    # neotest-rust drives cargo-nextest; debugging its tests expects codelldb, which is not shipped.
    extraPackages =
      [
        pkgs.rust-analyzer
        pkgs.cargo
        pkgs.rustc
      ]
      ++ lib.optional testEnabled pkgs.cargo-nextest;

    plugins =
      [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.rust]))
      ]
      ++ lib.optionals testEnabled (lazy {
        plugin = vimPlugins.neotest-rust.overrideAttrs (_: {
          dependencies = [];
          doCheck = false;
        });
        event = ["User HmNeotestAdapters"];
        config = ''
          addNeotestAdapter(function()
            return require("neotest-rust")({ args = { "--no-capture" } })
          end)
        '';
      });

    initLua = ''
      addLspServer("rust_analyzer", {
       	settings = {
       		diagnostics = {
       			enable = true,
       		},
       	},
       })
    '';
  })
