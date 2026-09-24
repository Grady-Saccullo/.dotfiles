{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "protobuf";
  extraConfig = _: {
    ai.lspServers.protobuf = {
      command = "${pkgs.protols}/bin/protols";
      extensionToLanguage = {
        ".proto" = "proto";
      };
      description = "protobuf language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.proto]))
  ];

  extraPackages = [
    pkgs.protols
  ];

  initLua = ''
    addLspServer("protols", {
      -- Add support for monorepo where protols.toml may not be in the root of the repo
      root_markers = { ".protols.toml", "protols.toml", ".git" }
    })
  '';
})
