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
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;

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
  in
    lib.mkIf cfg.enable (utils.mkHomeManagerUser {
      programs.neovim = {
        enable = true;
        package = pkgs.unstable.neovim-unwrapped;

        defaultEditor = true;
        withNodeJs = true;
        vimAlias = true;

        extraPackages = with pkgs.unstable; [
          alejandra
          bash-language-server
          lua-language-server
          nil
          ripgrep
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
          ${builtins.readFile ./opt.lua}

          -- [START] shared lsp serves table ---

          -- shared table for us to be able to attach lsp servers to dynamically --
          local lsp_servers = {
            bashls = {},
            lua_ls = {
              Lua = {
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
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

          -- [END] shared lsp serves table ---

        '';

        plugins =
          [
            {
              plugin = treesitter-plugins;
              config = builtins.readFile ./nvim-treesitter.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.nvim-lspconfig;
              config = builtins.readFile ./nvim-lspconfig.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.gitsigns-nvim;
              config = builtins.readFile ./gitsigns-nvim.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.nvim-autopairs;
              config = builtins.readFile ./nvim-autopairs.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.nvim-cmp;
              config = builtins.readFile ./nvim-cmp.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.oxocarbon-nvim;
              config = builtins.readFile ./oxocarbon-nvim.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.telescope-nvim;
              config = builtins.readFile ./telescope-nvim.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.vim-slime;
              config = builtins.readFile ./vim-slime.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.ts-comments-nvim;
              config = builtins.readFile ./ts-comments-nvim.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.todo-comments-nvim;
              config = builtins.readFile ./todo-comments-nvim.lua;
              type = "lua";
            }

            vimPlugins.cmp-buffer
            vimPlugins.cmp-git
            vimPlugins.cmp-nvim-lsp
            vimPlugins.cmp-nvim-lua
            vimPlugins.cmp-path
            vimPlugins.cmp_luasnip
            {
              plugin = vimPlugins.fidget-nvim;
              config = builtins.readFile ./fidget-nvim.lua;
              type = "lua";
            }
            vimPlugins.friendly-snippets
            {
              plugin = vimPlugins.harpoon2;
              config = builtins.readFile ./harpoon.lua;
              type = "lua";
            }
            vimPlugins.lspkind-nvim
            vimPlugins.luasnip
            {
              plugin = vimPlugins.conform-nvim;
              config = builtins.readFile ./conform.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.nvim-treesitter-context;
              config = "require('treesitter-context').setup()";
              type = "lua";
            }
            {
              plugin = vimPlugins.nvim-treesitter-textobjects;
              config = builtins.readFile ./nvim-treesitter-textobjects.lua;
              type = "lua";
            }
            {
              plugin = vimPlugins.treesitter-modules-nvim;
              config = builtins.readFile ./treesitter-modules.lua;
              type = "lua";
            }
            vimPlugins.plenary-nvim
            vimPlugins.telescope-fzf-native-nvim
            vimPlugins.telescope-ui-select-nvim
            vimPlugins.vim-fugitive
            vimPlugins.vim-rhubarb
            vimPlugins.vim-vinegar
            {
              plugin = vimPlugins.smart-splits-nvim;
              config = builtins.readFile ./smart-splits.lua;
              type = "lua";
            }
          ]
          ++ lib.optionals enable-nvim-ts-autotag [
            {
              plugin = vimPlugins.nvim-ts-autotag;
              config = builtins.readFile ./nvim-ts-autotag.lua;
              type = "lua";
            }
          ];
      };

      home.file."./.config/nvim/after/" = {
        source = ./after;
        recursive = true;
      };
    });
}
