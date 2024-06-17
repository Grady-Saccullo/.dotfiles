{ pkgs, ...}:
{
	xdg.configFile."nvim".source = ../../configs/nvim/.config/nvim;

	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;
			viAlias = true;
			vimAlias = true;
		};
	};
}
