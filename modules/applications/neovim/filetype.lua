-- [START] filetype.lua --
vim.filetype.add({
	extension = {
		zsh = "sh",
		sh = "sh",
		-- TODO: figure out if i can move this into templ setup and not have issues with merging tables
		templ = "templ",
		tmpl = "templ",
	},
	filename = {
		[".zshrc"] = "sh",
		[".zshenv"] = "sh",
		[".zsh"] = "sh",
	},
})
-- [END] filetype.lua --
