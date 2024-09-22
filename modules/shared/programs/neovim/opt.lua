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

o.mouse = 'a'

-- Spellcheck --
o.spelllang = 'en_us'
o.spell = true
