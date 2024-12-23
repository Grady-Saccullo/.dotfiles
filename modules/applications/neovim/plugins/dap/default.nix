{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  vimPlugins = pkgs.unstable.vimPlugins;
  cfg = config.applications.neovim.dap;
  inherit (lib) mkEnableOption;
in {
  options = {
    applications.neovim.dap = {
      enable = mkEnableOption "Dap";
      go.enable = mkEnableOption "Dap / Go";
    };
  };

  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    programs.neovim.plugins =
      [
        {
          plugin = vimPlugins.nvim-dap;
          config = builtins.readFile ./dap.lua;
          type = "lua";
        }
        {
          plugin = vimPlugins.nvim-dap-ui;
          config = builtins.readFile ./dap-ui.lua;
          type = "lua";
        }
        vimPlugins.nvim-nio
      ]
      ++ lib.optionals cfg.go.enable [
        {
          plugin = vimPlugins.nvim-dap-go;
          config = builtins.readFile ./dap-go.lua;
          type = "lua";
        }
      ];

    programs.neovim.extraPackages = lib.optionals cfg.go.enable [
      pkgs.unstable.delve
    ];
  });
}
#     lib.mkIf cfg.enable (self.utils.mkHomeManagerUser ({
#         programs.neovim.plugins = [
#           {
#             plugin = vimPlugins.nvim-dap;
#             config = builtins.readFile ./dap.lua;
#             type = "lua";
#           }
#           {
#             plugin = vimPlugins.nvim-dap-ui;
#             config = builtins.readFile ./dap-ui.lua;
#             type = "lua";
#           }
#           vimPlugins.nvim-nio
#         ];
#       }
#       // (lib.mkIf cfg.go.enable {
#         programs.neovim.extraPackages = [
#           pkgs.unstable.delve
#         ];
#         programs.neovim.plugins = [
#           {
#             plugin = vimPlugins.nvim-dap-go;
#             config = builtins.readFile ./dap-go.lua;
#             type = "lua";
#           }
#         ];
#       })));
# }

