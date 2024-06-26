# Prompt the user for a yes/no response
#
# This function presents a prompt to the user and waits for a yes or no answer.
# It will continue to ask until a valid response is given.
#
# Usage:
#   prompt_yes_no "Do you want to continue?"
#
# Arguments:
#   $1 - The prompt message to display to the user
#
# Returns:
#   0 user answered yes
#   1 user answered no
#
# Example:
#   if prompt_yes_no "Do you want to proceed?"; then
#       echo "User chose to proceed."
#   else
#       echo "User chose not to proceed."
#   fi
#
function prompt_yes_no() {
    local prompt="$1"
    local response

    while true; do
        read -rp "$prompt (y/n): " response
        case "$response" in
            [yY][eE][sS]|[yY]) 
                return 0
                ;;
            [nN][oO]|[nN])
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}
