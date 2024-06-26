{ pkgs, config, ... }:
let 
	configDir = /home/hackerman/.dotfiles/configs/nvim/.config/nvim;
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
