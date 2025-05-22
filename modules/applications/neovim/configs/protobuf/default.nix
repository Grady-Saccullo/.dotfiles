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
    "protobuf.enable"
  ];
in {
  options = {
    applications.neovim.protobuf = {
      enable = mkEnableOption "Protobuf";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.proto]))
      ];
      programs.neovim.extraPackages = [
        pkgs.unstable.protols
      ];
      programs.neovim.extraLuaConfig = ''
        addLspServer("protols", {})
      '';
    });
}
