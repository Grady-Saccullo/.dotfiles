{ pkgs, inputs, ...}:
{
	xdg.configFile."nvim".source = inputs.submoduleNvim;

	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;
			viAlias = true;
			vimAlias = true;
		};
	};
}
