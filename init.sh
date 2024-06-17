
# Install all necessary deps which need to be installed via curl
printf "Setting up initial tooling\n"

# run: checks if a tool is installed, and if not, installs it using a command
# args:
# $1: name of the tool
# $2: bool value to check if the tool is installed
# $3: command to run to install the tool
# $4: optional args to run post install command
run() {
	printf "%s: Checking install... " "$1"

	eval "which $2 > /dev/null"
	installed=$?

	if [ "$installed" = 0 ]; then
		printf "✅"
	else
		printf "⏳"
		/bin/bash -c "$($3) $4"
		printf " -> ✅"
	fi

	printf "\n"
}

./sync.sh

# Need to get some tools installed before we can do anything else

run "Xcode" "xcode-select" "xcode-select --install"

run "Nix" "nix" "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix" "| sh -s -- install"

run ./nix/sync.sh

printf "Setting up repos"
cd ./repos || exit
stow -v -t ~/ .
printf " -> ✅\n"
