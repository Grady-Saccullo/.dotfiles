source "$SCRIPT_DIR/lib/nix-config.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/prompt-yes-no.sh"


# LOCAL FILE USE ONLY
#
# Test the config for darwin system type
function _command_test_config_darwin() {
	local config_name
	config_name="$(read_nix_config)"

	nix build \
		--show-trace \
		--verbose \
		--extra-experimental-features 'nix-command flakes' \
		"$(pwd)#darwinConfigurations.$config_name.system"

	./result/sw/bin/darwin-rebuild check --flake "$(pwd)#$config_name"
}


# LOCAL FILE USE ONLY
#
# Test the config for nixos system type
function _command_test_config_nixos() {
	local config_name
	config_name="$(read_nix_config)"

	sudo nixos-rebuild test --flake "$(pwd)#$config_name"
}

# LOCAL FILE USE ONLY
#
# Test the config for generic linux system type
function _command_test_config_generic_linux() {
	local config_name
	config_name="$(read_nix_config)"
	echo "NOT YET IMPLEMENTED: generic linux"
	exit 1
}

# Test to a specified Nix configuration or use the current one
#
# This function handles testing Nix configurations. It can use
# the currently set configuration or a new one specified as an argument.
# If no argument is provided, it prompts the user to confirm using the 
# current configuration.
#
# Usage:
#   command_test_config [config_name]
#
# Arguments:
#   $1 - config_name (optional): The name of the Nix configuration to test to
#
# Returns:
#	void
#
# Exit Status:
#   1 if the user decides not to proceed with the current config when no argument is provided
#
function command_test_config() {
	local config_name
	config_name="$(read_nix_config)"

	if [ $# -eq 0 ]; then
		if ! prompt_yes_no "No config passed. Use current config, $config_name, to rebuild?"; then
			echo "Please try again with desired configuration name"
			exit 1
		fi
	else
		config_name="$1"
	fi

	set_nix_config "$config_name"

	run_for_system \
		_command_test_config_darwin \
		_command_test_config_nixos \
		_command_test_config_generic_linux
}
