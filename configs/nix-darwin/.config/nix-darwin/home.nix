{ pkgs, ...}:

{
	home.stateVersion = "24.05";

	home.packages = with pkgs; [
		jq
		htop
	];

	# programs = {
	# 	zsh = {
	# 		enable = true;
	# 	};
	# };
}


