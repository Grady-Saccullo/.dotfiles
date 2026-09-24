{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["docker"];
  # Only dockerls reaches the AI bus. Claude Code maps servers by file
  # extension, so a bare `Dockerfile` is not matched and compose files
  # (docker-compose.yml, compose.yaml) cannot be targeted without claiming
  # every YAML file.
  extraConfig = _: {
    ai.lspServers.docker = {
      command = "${pkgs.dockerfile-language-server}/bin/docker-langserver";
      args = ["--stdio"];
      extensionToLanguage = {
        ".dockerfile" = "dockerfile";
        ".Dockerfile" = "dockerfile";
      };
      description = "docker language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.docker-compose-language-service
    pkgs.dockerfile-language-server
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.dockerfile]))
  ];

  initLua = ''
    addLspServer("docker_compose_language_service", {})
    addLspServer("dockerls", {})
  '';
})
