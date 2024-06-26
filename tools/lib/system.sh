# Determine if the current system is NixOS
#
# This function checks if the system is running NixOS by looking for 'ID=nixos'
# in the /etc/os-release file, if it exists.
#
# Usage:
#   is_nixos
#
# Returns:
#   0 if the system is NixOS
#   1 if the system is not NixOS or if /etc/os-release doesn't exist
#
# Example:
#   if is_nixos; then
#       echo "This is a NixOS system"
#   else
#       echo "This is not a NixOS system"
#   fi
#
function is_nixos() {
    if [ -f /etc/os-release ] && grep -q 'ID=nixos' /etc/os-release; then
        return 0
    else
        return 1
    fi
}

# Determine the operating system type
#
# This function returns the kernel name of the operating system,
# which is typically used to identify the OS type (e.g., Linux, Darwin).
#
# Usage:
#   current_system
#
# Returns:
#   Prints the kernel name to stdout. Common values include:
#   - "Linux" for Linux-based systems
#   - "Darwin" for macOS
#   - "FreeBSD" for FreeBSD systems
#
# Exit Status:
#   Returns the exit status of the uname command (typically 0 for success)
#
# Example:
#   os=$(current_os)
#   echo "Current system type: $os"
#
# Note:
#   This function uses the uname command with the -s flag, which is 
#   POSIX-compliant and should work on most Unix-like operating systems.
#
function current_os() {
	uname -s
}


# Run appropriate function based on the system type. Function will
# exit 1 if no match found.
#
# Usage: run_for_system <darwin_func> <nixos_func> <generic_linux_func>
#
# Parameters:
#   $1 - Function to run for Darwin (macOS) systems
#   $2 - Function to run for NixOS systems
#   $3 - Function to run for generic Linux systems
#
# Returns:
#	void
#
# Example:
#   run_for_system \
#		setup_darwin \
#		setup_nixos \
#		setup_generic_linux
#
function run_for_system() {
	local os
	os=$(current_os)
	case "$os" in
		Darwin)
			$1
			;;
		Linux)
			if is_nixos; then
				$2
			else
				$3
			fi
			;;
		*)
			echo "Unsupported system type"
			exit 1
			;;
		esac
}
