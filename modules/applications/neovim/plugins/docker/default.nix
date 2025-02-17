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
    "docker.enable"
  ];
in {
  options = {
    applications.neovim.docker = {
      enable = mkEnableOption "Docker";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.extraPackages = [
        pkgs.unstable.docker-compose-language-service
        pkgs.unstable.dockerfile-language-server-nodejs
      ];
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.dockerfile]))
      ];

      programs.neovim.extraLuaConfig = ''
        addLspServer("docker_compose_language_service", {})
        addLspServer("dockerls", {})
      '';
    });
}
