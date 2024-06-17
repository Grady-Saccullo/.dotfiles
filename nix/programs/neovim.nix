{ pkgs, ...}:
{
	xdg.configFile."nvim".source = builtins.readDir ../../configs/nvim/.config/nvim;
	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;
		};
	};
}
