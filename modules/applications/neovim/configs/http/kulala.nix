{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["http" "kulala"];
} ({vimPlugins, ...}: {
  plugins = [
    {
      plugin = vimPlugins.kulala-nvim;
      config = builtins.readFile ./kulala-nvim.lua;
      type = "lua";
    }
  ];

  extraPackages = [
    pkgs.unstable.curl
  ];
})
