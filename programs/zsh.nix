
{ ... }:
{
	programs = {
		zsh = {
			enable = true;

			shellAliases = {
				l = "ls -la";
			};

			oh-my-zsh = {
				enable = true;

				plugins = [
					"git"
				];
				theme = "robbyrussell";
			};
		};
	};
}
