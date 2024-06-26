{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
	buildInputs = with pkgs; [
		gnumake
		vim
		git
	];

	shellHook = ''
		echo "Welcome to the setup shell!"
		echo ""
		echo "This shell provides the necessary tooling for getting"
		echo "the system up and running. (make, vim, git)"
		echo ""
		echo "To get a new host up and running the following must be"
		echo "run."
		echo "	1. 'make set-system-type'"
		echo "	2. 'make switch'"
	'';
}
