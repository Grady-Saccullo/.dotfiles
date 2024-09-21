-- Might play with Neovide https://neovide.dev/ --
if vim.g.neovide then
  	vim.g.neovide_cursor_trail_legnth = 0
  	vim.g.neovide_cursor_animation_length = 0
  	vim.o.guifont = "Hack Nerd Font Mono"
end

-- Set leader and localleader keys ---
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Copilot ---
vim.g.copilot_no_tab_map = true
