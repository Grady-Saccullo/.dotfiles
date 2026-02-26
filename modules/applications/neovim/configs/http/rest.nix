{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["http" "rest"];
} ({vimPlugins, ...}: {
  plugins = [
    {
      plugin = vimPlugins.rest-nvim;
      config = builtins.readFile ./rest-nvim.lua;
      type = "lua";
    }
  ];

  extraPackages = [
    pkgs.unstable.curl
  ];

  extraLuaPackages = ps: with ps; [
    xml2lua
    mimetypes
  ];
})
