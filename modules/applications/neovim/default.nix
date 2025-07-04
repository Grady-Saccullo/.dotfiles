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
          stylua
          yaml-language-server
          vscode-langservers-extracted
        ];

        extraLuaConfig = ''
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
            vimPlugins.fidget-nvim
            vimPlugins.friendly-snippets
            vimPlugins.harpoon2
            vimPlugins.lspkind-nvim
            vimPlugins.luasnip
            vimPlugins.neoformat
            vimPlugins.nvim-treesitter-context
            vimPlugins.nvim-treesitter-textobjects
            vimPlugins.plenary-nvim
            vimPlugins.telescope-fzf-native-nvim
            vimPlugins.vim-fugitive
            vimPlugins.vim-rhubarb
            vimPlugins.vim-vinegar
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
