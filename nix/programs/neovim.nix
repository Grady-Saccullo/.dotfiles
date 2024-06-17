{ pkgs-unstable, ...}:
{
	xdg.configFile."nvim".source = ../../configs/nvim/.config/nvim;
	programs = {
		neovim = {
			enable = true;
			package = pkgs-unstable.neovim;
		};
	};
}
