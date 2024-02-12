
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

# Need to get some tools installed before we can do anything else

run "Xcode" "xcode-select" "xcode-select --install"

run "Nix" "nix" "curl -L https://nixos.org/nix/install" "--darwin-use-unencrypted-nix-store-volume"

run "Homebrew" "brew" "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

run "Stow" "stow" "brew install -q stow"


# move to ../configs and run stow
cd ./configs || exit
stow -nv -t ~/ *

cd .. || exit

cd ./repos || exit
stow -nv -t ~/ .

