{ nixpkgs-unstable, ...}:
{
	xdg.configFile."nvim".source = ../../configs/nvim/.config/nvim;
	programs = {
		neovim = {
			enable = true;
			package = nixpkgs-unstable.neovim;
		};
	};
}
