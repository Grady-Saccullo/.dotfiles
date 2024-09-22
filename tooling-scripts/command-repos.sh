function command_repos() {
	case "$1" in
		sync)
			echo "sync down for all git submodules"
			;;
		*)
			echo "Error: command not found"
			exit 1
			;;
	esac
}
