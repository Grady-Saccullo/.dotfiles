-- [START] vim-slime.lua --
vim.g.slime_target = "tmux"
vim.cmd([[
	let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}
]])
vim.g.slime_dont_ask_default = 1
-- [END] vim-slime.lua --
