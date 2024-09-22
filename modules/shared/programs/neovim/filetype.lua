-- Setup file types --
vim.filetype.add({
	extension = {
		zsh = "sh",
		sh = "sh",
		extension = { templ = "templ" },
	},
	filename = {
		[".zshrc"] = "sh",
		[".zshenv"] = "sh",
		[".zsh"] = "sh",
	},
})
