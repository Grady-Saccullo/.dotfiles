-- [START] oxocarbon-nvim.lua --
vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.cmd("colorscheme oxocarbon")

-- Make background transparent
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })

-- Give floating windows (hover, diagnostics) the same bg as the completion menu
local pmenu_hl = vim.api.nvim_get_hl(0, { name = "Pmenu" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = pmenu_hl.bg })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = pmenu_hl.bg })

-- Fix cursor line (make it slightly visible but still transparent)
vim.api.nvim_set_hl(0, "CursorLine", { bg = "none", bold = true })
vim.api.nvim_set_hl(0, "CursorLineNr", { bg = "none" })

-- Fix statusline and tabline (buffer names)
vim.api.nvim_set_hl(0, "StatusLine", { bg = "none" })
vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLine", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "none", bold = true })

vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })

-- [END] oxocarbon-nvim.lua --
