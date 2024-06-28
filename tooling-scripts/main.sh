#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SCRIPT_DIR

source "$SCRIPT_DIR/command-switch-config.sh"
source "$SCRIPT_DIR/command-format.sh"
source "$SCRIPT_DIR/lib/system.sh"


function print_usage() {
	echo "Usage: $0 <command> [options]"
	echo "Commands:"
	echo "	switch <config name>"
	echo "	check <config name> [--verbose]"
}


function main() {
	if [ $# -eq 0 ]; then
		print_usage
		exit 1
	fi

	local command="$1"
	shift

	case "$command" in
		switch)
			command_switch_config "$@"
			;;
		format)
			command_format "$@"
			;;
		*)
			echo "Error: command not found"
			print_usage
			;;
	esac
}

main "$@"
