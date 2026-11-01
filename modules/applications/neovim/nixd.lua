-- [START] nixd.lua --
-- nixd evaluates these expressions from its own cwd, so the flake root is embedded as an absolute path.
local flake_root = vim.fs.root(vim.fn.getcwd(), "flake.nix")
local function flake_expr(body)
	return ('let f = builtins.getFlake "%s"; in %s'):format(flake_root, body)
end
local darwin_options = "let d = f.darwinConfigurations or {}; n = builtins.attrNames d; in"
	.. " if n == [] then {} else (d.${builtins.head n}).options"

local nixd = {
	formatting = { command = { "alejandra" } },
	nixpkgs = { expr = "import <nixpkgs> {}" },
}
if flake_root then
	nixd.nixpkgs.expr = flake_expr("import (f.inputs.nixpkgs-unstable or f.inputs.nixpkgs or <nixpkgs>) {}")
	nixd.options = {
		darwin = { expr = flake_expr(darwin_options) },
		home_manager = {
			expr = flake_expr(
				"let o = "
					.. darwin_options
					.. "; in if o == {} then {} else o.home-manager.users.type.getSubOptions []"
			),
		},
	}
end

-- Info-level tracing on stderr would otherwise fill lsp.log at ERROR level.
addLspServer("nixd", { cmd = { "nixd", "--log=error" }, settings = { nixd = nixd } })
-- [END] nixd.lua --
