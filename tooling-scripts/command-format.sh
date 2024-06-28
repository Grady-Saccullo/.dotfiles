function command_format() {
	if [ $# -eq 0 ]; then
		echo "format uses https://github.com/kamadorueda/alejandra"
		echo ""
		alejandra --help
		exit 0
	fi

	alejandra "$@"
}
