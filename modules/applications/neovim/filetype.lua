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
		[".gitlab-ci.yml"] = "yaml.gitlab",
		["docker-compose.yml"] = "yaml.docker-compose",
		["docker-compose.yaml"] = "yaml.docker-compose",
		["compose.yml"] = "yaml.docker-compose",
		["compose.yaml"] = "yaml.docker-compose",
	},
	pattern = {
		[".*/charts?/[^/]+/values%.ya?ml"] = "yaml.helm-values",
		-- Only a chart's values file, so a stray values.yaml elsewhere stays plain yaml.
		["values%.ya?ml"] = function(path)
			if vim.uv.fs_stat(vim.fs.dirname(path) .. "/Chart.yaml") then
				return "yaml.helm-values"
			end
		end,
	},
})
-- [END] filetype.lua --
