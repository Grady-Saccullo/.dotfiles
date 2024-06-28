# Set the Nix configuration name
#
# This function sets the Nix configuration name by writing it to a file
# named .nix-config-name in the current directory.
#
# Usage:
#   set_nix_config <config_name>
#
# Arguments:
#   $1 - config_name: The name of the Nix configuration to set
#
# Output:
#   Writes the configuration name to ./.nix-config-name
#
# Exit Status:
#   0 if successful
#   1 if no configuration name is provided
#
# Example:
#   set_nix_config "my-custom-config"
#
# Note:
#   This function will overwrite the existing .nix-config-name file
#   if it already exists.
#
function set_nix_config() {
	if [ $# -eq 0 ]; then
		echo "Error: Missing system type name"
		exit 1
	fi

	echo "$1" > ./.nix-config-name
}

# Read the current Nix configuration name
#
# This function reads the Nix configuration name from the .nix-config-name
# file in the current directory. If the file doesn't exist or can't be read,
# it returns "personal" as the default value.
#
# Usage:
#   read_nix_config
#
# Output:
#   Prints the Nix configuration name to stdout
#
# Returns:
#   The Nix configuration name if .nix-config-name exists and is readable
#   "personal" if the file doesn't exist or can't be read
#
# Exit Status:
#   Always returns 0 (success)
#
# Example:
#   current_config=$(read_nix_config)
#   echo "Current Nix configuration: $current_config"
#
# Note:
#   This function suppresses error messages from cat when the file is not found.
function read_nix_config() {
	cat ./.nix-config-name 2>/dev/null || echo "personal"
}
