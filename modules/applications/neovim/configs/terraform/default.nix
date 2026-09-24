{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = "terraform";
  extraConfig = _: {
    ai.lspServers.terraform = {
      command = "${pkgs.terraform-ls}/bin/terraform-ls";
      args = ["serve"];
      extensionToLanguage = {
        ".tf" = "terraform";
        ".tfvars" = "terraform-vars";
      };
      description = "terraform language server for AI tools";
    };
  };
} ({vimPlugins, ...}: {
  extraPackages = [
    pkgs.terraform-ls
  ];

  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.hcl p.terraform]))
  ];

  initLua = ''
    addLspServer("terraformls", {})
  '';
})
