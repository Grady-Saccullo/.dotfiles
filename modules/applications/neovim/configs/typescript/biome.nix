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
    "typescript.enable"
    "typescript.biome.enable"
  ];
in {
  options = {
    applications.neovim.typescript.biome = {
      enable = mkEnableOption "TypeScript / Biome";
    };
  };

  config = mkIf enable (mkHomeManagerUser {
    programs.neovim.extraPackages = [
      pkgs.unstable.biome
    ];

    programs.neovim.extraLuaConfig = ''
      addLspServer("biome", {})
    '';
  });
}
