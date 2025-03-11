{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;
  enable = allEnable config.applications.neovim [
    "enable"
    "zig.enable"
  ];
in {
  options = {
    applications.neovim.zig = {
      enable = mkEnableOption "Zig";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.extraPackages = [
        pkgs.unstable.zls
      ];
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.zig]))
        vimPlugins.zig-vim
      ];

      programs.neovim.extraLuaConfig = ''
        addLspServer("zls", {
            enable_build_on_save = true
        })
      '';
    });
}
