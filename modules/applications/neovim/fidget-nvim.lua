require("fidget").setup({
  -- LSP progress is in the statusline (opt.lua); fidget stays as the vim.notify UI.
  progress = { poll_rate = false },
  notification = {
    window = {
      winblend = 100,
    },
  },
})
