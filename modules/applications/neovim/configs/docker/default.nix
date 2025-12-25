{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["docker"];
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.unstable.docker-compose-language-service
    pkgs.unstable.dockerfile-language-server
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.dockerfile]))
  ];

  extraLuaConfig = ''
    addLspServer("docker_compose_language_service", {})
    addLspServer("dockerls", {})
  '';
})
