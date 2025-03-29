{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;
  enable = allEnable config.applications.neovim [
    "enable"
    "terraform.enable"
  ];
in {
  options = {
    applications.neovim.terraform = {
      enable = mkEnableOption "Terraform";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.extraPackages = [
        pkgs.unstable.terraform-ls
      ];
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.hcl p.terraform]))
      ];

      programs.neovim.extraLuaConfig = ''
        addLspServer("terraformls", {})
        vim.api.nvim_create_autocmd({"BufWritePre"}, {
          pattern = {"*.tf", "*.tfvars"},
          callback = function()
            vim.lsp.buf.format()
          end,
        })
      '';
    });
}
