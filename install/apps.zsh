dir=$(dirname $0)

if [[ $(uname) == "Darwin" ]]; then
	echo "Root: macOS detected"
	source "$dir/apps-macos.zsh"
else
	echo "Unsupported OS"
	exit 1
fi
