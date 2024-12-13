{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
  cfg = config.applications.neovim.docker;
in {
  options = {
    applications.neovim.docker = {
      enable = mkEnableOption "Docker";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
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
