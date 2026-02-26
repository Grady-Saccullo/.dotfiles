{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "terraform";
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.unstable.terraform-ls
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.hcl p.terraform]))
  ];

  initLua = ''
    addLspServer("terraformls", {})
  '';
})
