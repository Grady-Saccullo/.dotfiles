source "$SCRIPT_DIR/lib/nix-config.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/prompt-yes-no.sh"


# LOCAL FILE USE ONLY
#
# Switch the config for darwin system type
function _command_switch_config_darwin() {
	local config_name
	config_name="$(read_nix_config)"
	nix build \
		--extra-experimental-features 'nix-command flakes' \
		"$(pwd)#darwinConfigurations.$config_name.system"

	./result/sw/bin/darwin-rebuild switch \
		--flake "$(pwd)#$config_name"
}


# LOCAL FILE USE ONLY
#
# Switch the config for nixos system type
function _command_switch_config_nixos() {
	local config_name
	config_name="$(read_nix_config)"
	echo "NOT YET IMPLEMENTED: nixos"
	exit 1
}

# LOCAL FILE USE ONLY
#
# Switch the config for generic linux system type
function _command_switch_config_generic_linux() {
	local config_name
	config_name="$(read_nix_config)"
	echo "NOT YET IMPLEMENTED: generic linux"
	exit 1
}

# Switch to a specified Nix configuration or use the current one
#
# This function handles switching between Nix configurations. It can use
# the currently set configuration or a new one specified as an argument.
# If no argument is provided, it prompts the user to confirm using the 
# current configuration.
#
# Usage:
#   switch_config [config_name]
#
# Arguments:
#   $1 - config_name (optional): The name of the Nix configuration to switch to
#
# Returns:
#	void
#
# Exit Status:
#   1 if the user decides not to proceed with the current config when no argument is provided
#
function command_switch_config() {
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
		_command_switch_config_darwin \
		_command_switch_config_nixos \
		_command_switch_config_generic_linux
}
