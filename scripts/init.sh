# Install all necessary deps which need to be installed via curl
printf "Setting up initial tooling\n"

# run: checks if a tool is installed, and if not, installs it using a command
# args:
# $1: name of the tool
# $2: bool value to check if the tool is installed
# $3: command to run to install the tool
# $4: additional args to pass to the command
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

run "Homebrew" "brew" "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

run "Lua" "luad" "brew install -q lua"

run "Luarocks" "luarocks" "brew install -q luarocks"

run "Nix" "nix" "curl -L https://nixos.org/nix/install" "--darwin-use-unencrypted-nix-store-volume"

/bin/bash -c "lua ./configs.lua"
