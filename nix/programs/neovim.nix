{ pkgs, ...}:
{
	xdg.configFile."nvim".source = ../../configs/nvim/.config/nvim/lua;
	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;
		};
	};
}
