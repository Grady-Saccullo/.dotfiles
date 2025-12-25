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

  extraLuaConfig = ''
    addLspServer("terraformls", {})
    vim.api.nvim_create_autocmd({"BufWritePre"}, {
      pattern = {"*.tf", "*.tfvars"},
      callback = function()
        vim.lsp.buf.format()
      end,
    })
  '';
})
