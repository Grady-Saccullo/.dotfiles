{ pkgs, ...}:
{
	xdg.configFile."nvim" = {
		source = ../../configs/nvim/.config/nvim;
		recursive = true;
	};

	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;
		};
	};
}
