-- Read by the plugin at load time; the devshell exports DATABASE_URL through direnv.nvim.
vim.g.db_ui_env_variable_url = "DATABASE_URL"
vim.g.db_ui_use_nerd_fonts = 1
-- Its SQL-buffer defaults sit on <leader>S/W/E, which are the session prefix and workspace keys.
vim.g.db_ui_disable_mappings_sql = 1
