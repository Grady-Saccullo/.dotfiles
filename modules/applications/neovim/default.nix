{
  pkgs,
  utils,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.neovim;
in {
  imports = [./configs];

  options = {
    applications.neovim = {
      enable = mkEnableOption "Neovim";
      package = lib.mkPackageOption pkgs "neovim-unwrapped" {};
    };
  };

  config = let
    vimPlugins = pkgs.vimPlugins;
    lazy = import ./lazy.nix {inherit lib;};
    readFile = builtins.readFile;

    treesitter-plugins = vimPlugins.nvim-treesitter.withPlugins (p:
      with p; [
        bash
        comment
        diff
        gitcommit
        gitignore
        jq
        json
        lua
        make
        nix
        regex
        sql
        toml
        yaml
      ]);
    enable-nvim-ts-autotag = cfg.typescript.tsx.enable || cfg.html.enable;

    # smart-splits v3 ships no backends and nixpkgs has no package for this one.
    smart-splits-backend-wezterm = pkgs.vimUtils.buildVimPlugin {
      pname = "smart-splits-backend-wezterm";
      version = "0-unstable-2026-10-09";
      src = pkgs.fetchFromGitHub {
        owner = "smart-splits-nvim";
        repo = "backend-wezterm";
        rev = "ae840db696791f638c190c3e0534d2ddfcd5e6a7";
        hash = "sha256-9kDZAoYqQMtSGAE9w70UtkW/DLUmmwVAwCxDxk8om1E=";
      };
      dependencies = [vimPlugins.smart-splits-nvim];
    };
  in
    lib.mkIf cfg.enable (utils.mkHomeManagerUser {
      programs.neovim = {
        enable = true;
        package = cfg.package;

        defaultEditor = true;
        withNodeJs = true;
        vimAlias = true;

        extraPackages = with pkgs; [
          alejandra
          bash-language-server
          lua-language-server
          nil
          prettier
          ripgrep
          shellcheck
          shfmt
          stylua
          yaml-language-server
          yamlfmt
          vscode-langservers-extracted
        ];

        initLua = ''
          ${builtins.readFile ./filetype.lua}
          ${builtins.readFile ./globals.lua}
          ${builtins.readFile ./highlight.lua}
          ${builtins.readFile ./keymap.lua}
          ${builtins.readFile ./diagnostic.lua}
          ${builtins.readFile ./opt.lua}

          -- [START] shared lsp serves table ---

          -- shared table for us to be able to attach lsp servers to dynamically --
          local lsp_servers = {
            bashls = {},
            lua_ls = {
              settings = {
                Lua = {
                  workspace = { checkThirdParty = false },
                  telemetry = { enable = false },
                },
              },
            },
            yamlls = {
              settings = {
                schemas = {},
              },
            },
            jsonls = {},
            nil_ls = {},
          }

          local function addLspServer(name, config)
            lsp_servers[name] = config
          end

          -- neotest adapters, as constructors so the adapter plugin can stay lazy --
          local neotest_adapters = {}
          local function addNeotestAdapter(make)
            table.insert(neotest_adapters, make)
          end

          -- [END] shared lsp serves table ---

        '';

        plugins =
          [
            # lz.n drives every pack/*/opt plugin; `:checkhealth hm-lazy` shows what loads when.
            {
              plugin = vimPlugins.lz-n;
              config = ''
                vim.g.lz_n = { load = require("hm-lazy").packadd }
              '';
              type = "lua";
              runtime = {
                "lua/hm-lazy/init.lua".source = ./lua/hm-lazy/init.lua;
                "lua/hm-lazy/health.lua".source = ./lua/hm-lazy/health.lua;
              };
            }
            {
              plugin = treesitter-plugins;
              config = readFile ./nvim-treesitter.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.nvim-lspconfig;
              config = readFile ./nvim-lspconfig.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.oxocarbon-nvim;
              config = readFile ./oxocarbon-nvim.lua;
              type = "lua";
            }
            # blink reads friendly-snippets and the git source off the runtimepath on demand.
            vimPlugins.friendly-snippets
            vimPlugins.blink-cmp-git
            {
              plugin = vimPlugins.blink-cmp;
              config = readFile ./blink-cmp.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.oil-nvim;
              config = readFile ./oil-nvim.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.direnv-nvim;
              config = readFile ./direnv-nvim.lua;
              type = "lua";
            }
            smart-splits-backend-wezterm
            {
              plugin = vimPlugins.smart-splits-nvim;
              config = readFile ./smart-splits.lua;
              type = "lua";
            }
          ]
          ++ lazy {
            plugin = vimPlugins.telescope-nvim;
            # LspAttach so ui-select owns vim.ui.select before the first code action.
            event = ["LspAttach"];
            cmd = ["Telescope"];
            keys = ["<leader>?" "<leader><space>" "<leader>/" "<leader>gf" "<leader>sf" "<leader>sh" "<leader>sw" "<leader>sg" "<leader>sd" "<leader>sr"];
            after = [vimPlugins.telescope-fzf-native-nvim vimPlugins.telescope-ui-select-nvim];
            config = readFile ./telescope-nvim.lua;
          }
          ++ lazy {
            plugin = vimPlugins.nvim-autopairs;
            event = ["InsertEnter"];
            config = readFile ./nvim-autopairs.lua;
          }
          ++ lazy {
            plugin = vimPlugins.fidget-nvim;
            event = ["LspAttach"];
            config = readFile ./fidget-nvim.lua;
          }
          ++ lazy {
            plugin = vimPlugins.gitsigns-nvim;
            event = ["BufReadPre" "BufNewFile"];
            config = readFile ./gitsigns-nvim.lua;
          }
          ++ lazy {
            plugin = vimPlugins.harpoon2;
            keys = ["<leader>ha" "<leader>hs" "<leader>hf" "<leader>h1" "<leader>h2" "<leader>h3" "<leader>h4" "[h" "]h"];
            config = readFile ./harpoon.lua;
          }
          ++ lazy {
            plugin = vimPlugins.conform-nvim;
            event = ["BufWritePre"];
            cmd = ["Format" "ConformInfo"];
            keys = ["<leader>f" "<leader>tf"];
            config = readFile ./conform.lua;
          }
          ++ lazy {
            plugin = vimPlugins.todo-comments-nvim;
            event = ["BufReadPost" "BufNewFile"];
            config = readFile ./todo-comments-nvim.lua;
          }
          ++ lazy {
            plugin = vimPlugins.ts-comments-nvim;
            event = ["BufReadPost" "BufNewFile"];
            config = readFile ./ts-comments-nvim.lua;
          }
          ++ lazy {
            plugin = vimPlugins.nvim-treesitter-context;
            event = ["BufReadPost" "BufNewFile"];
            config = "require('treesitter-context').setup()";
          }
          ++ lazy {
            plugin = vimPlugins.nvim-treesitter-textobjects;
            event = ["BufReadPost" "BufNewFile"];
            config = readFile ./nvim-treesitter-textobjects.lua;
          }
          ++ lazy {
            plugin = vimPlugins.vim-fugitive;
            cmd = ["Git" "G" "Gedit" "Gsplit" "Gvsplit" "Gtabedit" "Gdiffsplit" "Gvdiffsplit" "Ghdiffsplit" "Gread" "Gwrite" "Gwq" "Ggrep" "Glgrep" "Gclog" "Gllog" "Gcd" "Glcd" "GMove" "GRename" "GDelete" "GRemove" "GUnlink" "GBrowse"];
            after = [vimPlugins.vim-rhubarb];
          }
          ++ lazy {
            plugin = vimPlugins.vim-slime;
            keys = [
              {
                lhs = "<C-c><C-c>";
                mode = ["n" "x"];
              }
              "<C-c>v"
            ];
            cmd = ["SlimeSend" "SlimeConfig" "SlimeResolvePane"];
            config = readFile ./vim-slime.lua;
          }
          ++ lib.optionals enable-nvim-ts-autotag (lazy {
            plugin = vimPlugins.nvim-ts-autotag;
            event = ["InsertEnter"];
            config = readFile ./nvim-ts-autotag.lua;
          });
      };

      home.file."./.config/nvim/after/" = {
        source = ./after;
        recursive = true;
      };
    });
}
