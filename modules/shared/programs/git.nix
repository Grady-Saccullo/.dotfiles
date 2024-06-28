{ pkgs, ... }:
{
	programs = {
		git = {
			enable = true;
			package = pkgs.gitFull;

			userName = "Hackerman";
			userEmail = "gradys.dev@gmail.com";

			lfs = {
				enable= true;
			};

			delta = {
				enable = true;
			};

			extraConfig = {
				credential.helper = "oauth";
    		};
		};
	};
}
