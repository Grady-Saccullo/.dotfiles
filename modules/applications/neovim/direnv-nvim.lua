require("direnv").setup({
	autoload_direnv = true,
	-- The default <Leader>d* bindings collide with the DAP maps.
	keybindings = { allow = false, deny = false, reload = false, edit = false },
	notifications = { silent_autoload = true },
})
