if [[ $(uname) == "Darwin" ]]; then
	source "$PWD/apps-macos.zsh"
else
	echo "Unsupported OS"
	exit 1
fi
