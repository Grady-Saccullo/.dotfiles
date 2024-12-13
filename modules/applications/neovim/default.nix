{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.neovim;
in {
  imports = [./plugins];

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
        gitignore
        jq
        json
        lua
        make
        nix
        regex
        toml
        yaml
        diff
        gitignore
        gitcommit
      ]);
  in
    lib.mkIf cfg.enable (
      self.utils.mkHomeManagerUser {
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

          plugins = [
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

            vimPlugins.cmp-buffer
            vimPlugins.cmp-nvim-lsp
            vimPlugins.cmp-nvim-lua
            vimPlugins.cmp-path
            vimPlugins.cmp_luasnip
            vimPlugins.fidget-nvim
            vimPlugins.harpoon2
            vimPlugins.lspkind-nvim
            vimPlugins.luasnip
            vimPlugins.neoformat
            vimPlugins.nvim-treesitter-context
            vimPlugins.nvim-treesitter-textobjects
            vimPlugins.plenary-nvim
            vimPlugins.telescope-file-browser-nvim
            vimPlugins.telescope-fzf-native-nvim
            vimPlugins.vim-fugitive
            vimPlugins.vim-rhubarb
            vimPlugins.vim-vinegar
          ];
        };

        home.file."./.config/nvim/after/" = {
          source = ./after;
          recursive = true;
        };
      }
    );
}
