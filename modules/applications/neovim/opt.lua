-- [START] opt.lua --
local o = vim.opt

-- Leftside --
o.relativenumber = true
o.number = true

o.inccommand = "split"

o.showcmd = true
o.splitright = true
o.splitbelow = true

-- Turn back on if using Neovide
-- o.smoothscroll = true

-- Indenting --
o.autoindent = true
o.cindent = true
-- o.wrap = true
o.breakindent = true
o.linebreak = true

-- Tabbys --
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4

o.mouse = "a"

-- Spellcheck --
o.spelllang = "en_us"
o.spell = true

o.undofile = true

-- Folding: treesitter everywhere, swapped to the LSP foldexpr on attach where supported.
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99

-- Trusted .nvim.lua in a repo root (see :trust) carries per-project settings.
o.exrc = true
o.ignorecase = true
o.smartcase = true
o.signcolumn = "yes"
o.scrolloff = 8
o.updatetime = 250
-- The 0.12 default shows diagnostics and busy state but not LSP progress; g:lsp_progress is kept
-- up to date by the LspProgress autocmd in nvim-lspconfig.lua.
vim.o.statusline = " %{get(b:,'gitsigns_head','')} "
	.. (vim.o.statusline:gsub("%%=", "%%{get(g:,'lsp_progress','')}%%=", 1))
-- [END] opt.lua --
