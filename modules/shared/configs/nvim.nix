{ pkgs, config, ... }:
let 
	configDir = "${config.home.homeDirectory}/.dotfiles/configs/nvim/.config/nvim";
	# configDir = "../../configs/nvim/.config/nvim";
in {
	xdg.configFile."nvim" = {
		source = config.lib.file.mkOutOfStoreSymlink configDir;
		recursive = true;
	};

	programs = {
		neovim = {
			enable = true;
			package = pkgs.unstable.neovim-unwrapped;

			withPython3 = true;

			viAlias = true;
			vimAlias = true;
		};
	};
}
