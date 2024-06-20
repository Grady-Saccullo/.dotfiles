{ pkgs, config, ...}:
{
	xdg.configFile."nvim" = {
		source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/configs/nvim/.config/nvim";
		recursive = true;
	};

	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;
			viAlias = true;
			vimAlias = true;
		};
	};
}
