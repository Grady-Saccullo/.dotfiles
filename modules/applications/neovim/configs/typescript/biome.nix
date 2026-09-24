# biome is intentionally NOT contributed to ai.lspServers: it would claim the
# same `.ts` / `.js` extensions as the typescript server, and Claude Code only
# starts the first server registered per extension.
{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["typescript" "biome"];
} (_: {
  extraPackages = [
    pkgs.biome
  ];

  initLua = ''
    addLspServer("biome", {})
  '';
})
