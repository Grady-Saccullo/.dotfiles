{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["http" "rest"];
} ({
  vimPlugins,
  lazy,
  ...
}: {
  plugins = lazy {
    plugin = vimPlugins.rest-nvim;
    ft = ["http"];
    # Read by the plugin at load time.
    beforeConfig = "vim.g.rest_nvim = {}";
    config = builtins.readFile ./rest-nvim.lua;
  };

  extraPackages = [
    pkgs.curl
  ];

  extraLuaPackages = ps:
    with ps; [
      xml2lua
      mimetypes
    ];
})
