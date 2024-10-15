# ==================================================
# SSH Setup Script with Existing Key Selection Menu
# ==================================================
# Compatible with macOS and Linux
# Author: Noah Zoarki
# Date: 10/15/2024
# ==================================================

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display a header
function display_header() {
    clear
    printf "${BLUE}========================================${NC}\n"
    printf "${GREEN}       SSH Setup for Virtual Labs       ${NC}\n"
    printf "${BLUE}========================================${NC}\n"
    printf "\n"
}

# Function to display a step header
function display_step() {
    printf "${CYAN}----------------------------------------${NC}\n"
    printf "${YELLOW}%s${NC}\n" "$1"
    printf "${CYAN}----------------------------------------${NC}\n"
}

# Function to display an error message
function display_error() {
    printf "${RED}Error: %s${NC}\n" "$1"
}

# Function to display a success message
function display_success() {
    printf "${GREEN}%s${NC}\n" "$1"
}

# Function to pause and wait for user input
function pause() {
    read -rp "$(printf "${MAGENTA}Press Enter to continue...${NC}")"
}

# Detect the operating system and normalize
OS_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"

# Start of the script
display_header

# Step 1: SSH Key Management
display_step "Step 1: SSH Key Management"

# Offer to use an existing key or generate a new one
printf "${YELLOW}Would you like to use an existing SSH key or generate a new one?${NC}\n"
printf "1) Use an existing SSH key\n"
printf "2) Generate a new SSH key\n"
printf "\n"

read -rp "$(printf "${CYAN}Please select an option (1 or 2): ${NC}")" key_choice

if [ "$key_choice" = "1" ]; then
    # Use an existing key
    printf "\n"
    printf "${YELLOW}Scanning for existing SSH public keys...${NC}\n"
    pub_keys=("$HOME/.ssh/"*.pub)
    valid_pub_keys=()
    index=1

    # Check if any public keys are found
    if [ -e "${pub_keys[0]}" ]; then
        printf "\n"
        printf "${MAGENTA}Select an SSH public key from the list below:${NC}\n"
        printf "\n"
        for pub_key in "${pub_keys[@]}"; do
            key_name=$(basename "$pub_key")
            printf "  %d) %s\n" "$index" "$key_name"
            valid_pub_keys+=("$pub_key")
            ((index++))
        done
        printf "  %d) Enter a custom path\n" "$index"
        printf "\n"
        read -rp "$(printf "${CYAN}Please select a key (1-%d): ${NC}" "$index")" key_selection

        if [ "$key_selection" -ge 1 ] && [ "$key_selection" -lt "$index" ] 2>/dev/null; then
            selected_pub_key="${valid_pub_keys[$((key_selection - 1))]}"
            custom_key_path="${selected_pub_key%.pub}"
            printf "Using private key file: ${WHITE}%s${NC}\n" "$custom_key_path"
        elif [ "$key_selection" -eq "$index" ]; then
            read -e -rp "$(printf "${CYAN}Enter the path to your existing private key: ${NC}")" custom_key_path
            printf "Using private key file: ${WHITE}%s${NC}\n" "$custom_key_path"
            # Check if the file exists
            if [ ! -f "$custom_key_path" ]; then
                display_error "The specified private key file does not exist."
                exit 1
            fi
        else
            display_error "Invalid selection."
            exit 1
        fi
    else
        printf "${RED}No SSH public keys found in $HOME/.ssh/.${NC}\n"
        read -e -rp "$(printf "${CYAN}Enter the path to your existing private key: ${NC}")" custom_key_path
        printf "Using private key file: ${WHITE}%s${NC}\n" "$custom_key_path"
        # Check if the file exists
        if [ ! -f "$custom_key_path" ]; then
            display_error "The specified private key file does not exist."
            exit 1
        fi
    fi

    # Check and fix permissions if necessary
    if [[ "$OS_TYPE" == *"darwin"* ]]; then
        current_perms=$(stat -f "%Lp" "$custom_key_path")
    else
        current_perms=$(stat -c "%a" "$custom_key_path")
    fi

    if [ "$current_perms" != "600" ]; then
        printf "${YELLOW}Fixing permissions on %s${NC}\n" "$custom_key_path"
        chmod 600 "$custom_key_path"
    fi
else
    # Generate a new SSH key
    printf "\n"
    printf "${YELLOW}Select the algorithm for the SSH key:${NC}\n"
    printf "1) RSA (Recommended, secure)\n"
    printf "2) ECDSA (Elliptic Curve DSA)\n"
    printf "3) Ed25519 (Modern, fast, and secure)\n"
    printf "\n"
    read -rp "$(printf "${CYAN}Enter your choice (1-3): ${NC}")" algo_choice

    case $algo_choice in
        1 ) key_type="rsa -b 4096"; key_algorithm="rsa";;
        2 ) key_type="ecdsa -b 521"; key_algorithm="ecdsa";;
        3 ) key_type="ed25519"; key_algorithm="ed25519";;
        * ) display_error "Invalid selection."; exit 1;;
    esac

    printf "\n"
    read -rp "$(printf "${CYAN}Enter a name for your SSH key (e.g., '-SCHOOL'): ${NC}")" key_name
    custom_key_path="$HOME/.ssh/id_${key_algorithm}${key_name}"
    printf "Your SSH key will be saved at: ${WHITE}%s${NC}\n" "$custom_key_path"

    # Prompt for passphrase
    printf "\n"
    printf "${YELLOW}You can secure your SSH key with a passphrase (recommended).${NC}\n"
    printf "${MAGENTA}Note: Leaving it empty will create a key without a passphrase.${NC}\n"
    read -srp "$(printf "${CYAN}Enter passphrase: ${NC}")" passphrase
    printf "\n"
    read -srp "$(printf "${CYAN}Confirm passphrase: ${NC}")" passphrase_confirm
    printf "\n"

    if [ "$passphrase" != "$passphrase_confirm" ]; then
        display_error "Passphrases do not match."
        exit 1
    fi

    # Email comment
    printf "\n"
    read -rp "$(printf "${CYAN}Enter your email for the SSH key comment (optional): ${NC}")" email
    ssh_keygen_options=""
    if [ -n "$email" ]; then
        ssh_keygen_options="-C \"$email\""
    fi

    # Confirm and generate the SSH key
    printf "\n"
    printf "${YELLOW}Ready to generate SSH key with the following options:${NC}\n"
    printf "${GREEN}Algorithm :${NC} %s\n" "$key_algorithm"
    printf "${GREEN}Key Path  :${NC} %s\n" "$custom_key_path"
    printf "${GREEN}Passphrase:${NC} %s\n" "${passphrase:+[set]}"
    printf "${GREEN}Email     :${NC} %s\n" "${email:-[none]}"
    printf "\n"
    read -rp "$(printf "${CYAN}Proceed with key generation? (y/n): ${NC}")" confirm
    if [ "$confirm" != "y" ]; then
        display_error "SSH key generation cancelled."
        exit 1
    fi

    # Generate the SSH key
    if ! ssh-keygen -t $key_type -f "$custom_key_path" -N "$passphrase" $ssh_keygen_options; then
        display_error "Failed to generate the SSH key."
        exit 1
    fi
    display_success "New SSH key pair generated at $custom_key_path."
fi

pause

# Step 2: Adding SSH Key to ssh-agent
display_step "Step 2: Adding SSH Key to ssh-agent"

# Start the ssh-agent if it's not already running
if [ -z "$SSH_AGENT_PID" ]; then
    printf "${YELLOW}Starting ssh-agent...${NC}\n"
    eval "$(ssh-agent -s)"
fi

# Add the SSH private key to the ssh-agent
if [[ "$OS_TYPE" == *"darwin"* ]]; then
    # macOS specific command with Apple Keychain integration
    if ! ssh-add --apple-use-keychain "$custom_key_path"; then
        display_error "Failed to add SSH key to ssh-agent."
        exit 1
    fi
    display_success "SSH key added to ssh-agent and passphrase stored in Apple Keychain."
elif [[ "$OS_TYPE" == *"linux"* ]]; then
    # Linux specific command
    if ! ssh-add "$custom_key_path"; then
        display_error "Failed to add SSH key to ssh-agent."
        exit 1
    fi
    display_success "SSH key added to ssh-agent."
else
    display_error "Unsupported operating system: $OS_TYPE"
    exit 1
fi

pause

# Step 3: Remote Host and Group Configuration
display_step "Step 3: Remote Host and Group Configuration"

# Collect group information
printf "\n"
read -rp "$(printf "${CYAN}Enter the group code (e.g., '470'): ${NC}")" group_code
read -rp "$(printf "${CYAN}Enter the group name (e.g., 'CNIT 470 - Incident Response'): ${NC}")" group_name

# Collect host information
read -rp "$(printf "${CYAN}Enter the host alias (e.g., 'CentOS'): ${NC}")" host_alias
read -rp "$(printf "${CYAN}Enter the username for your remote host: ${NC}")" user
read -rp "$(printf "${CYAN}Enter the IP address or hostname of your remote host: ${NC}")" ip

ssh_hostname="${group_code}-${host_alias}"
printf "Constructed hostname: ${WHITE}%s${NC}\n" "$ssh_hostname"

# Validate IP address or hostname
if ! ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
    printf "${RED}Warning: Unable to reach %s. Please ensure it's correct.${NC}\n" "$ip"
fi

pause

# Step 4: Copy SSH Key to Remote Host
display_step "Step 4: Copy SSH Key to Remote Host"

printf "${YELLOW}Copying SSH public key to ${WHITE}%s@%s${NC}...\n" "$user" "$ip"
if ! ssh-copy-id -i "${custom_key_path}.pub" "${user}@${ip}"; then
    display_error "Failed to copy the SSH key to the host."
    exit 1
fi
display_success "SSH key successfully copied to the remote host."

pause

# Step 5: SSH Config File Management
display_step "Step 5: SSH Config File Management"

SSH_CONFIG_FILE="$HOME/.ssh/config"

# Ensure the SSH config file exists
touch "$SSH_CONFIG_FILE"

# Delimiter comments
START_MARKER="### SSH Configurations Managed by Script Start ###"
END_MARKER="### SSH Configurations Managed by Script End ###"

# Check if delimiters exist
if ! grep -q "$START_MARKER" "$SSH_CONFIG_FILE"; then
    printf "${YELLOW}Adding delimiters to SSH config file...${NC}\n"
    {
        printf "\n"
        printf "%s\n" "$START_MARKER"
        printf "%s\n" "$END_MARKER"
    } >> "$SSH_CONFIG_FILE"
    display_success "Delimiters added to SSH config file."
fi

# Read the content before the START_MARKER
before_content=$(sed "/$START_MARKER/,\$d" "$SSH_CONFIG_FILE")

# Read the content after the END_MARKER
after_content=$(sed "1,/$END_MARKER/d" "$SSH_CONFIG_FILE")

# Extract content between delimiters, excluding the markers themselves
config_content=$(sed -n "/$START_MARKER/,/$END_MARKER/p" "$SSH_CONFIG_FILE" | sed "1d;\$d")

# Prepare new content between markers
new_config_content="$START_MARKER"

# Check if group already exists in config_content
if echo "$config_content" | grep -q "^# Group: $group_name"; then
    printf "${GREEN}Group configuration for '%s' already exists. Adding host to the group.${NC}\n" "$group_name"
    # Extract existing group block
    group_block=$(echo "$config_content" | sed -n "/^# Group: $group_name/,/^# Group:/p")
    # If no next group, extract till the end
    if [ -z "$group_block" ]; then
        group_block=$(echo "$config_content" | sed -n "/^# Group: $group_name/,\$p")
    fi
    # Remove the group block from config_content
    config_content=$(echo "$config_content" | sed "/^# Group: $group_name/,/^# Group:/d")
else
    printf "${YELLOW}Adding new group configuration for '%s'.${NC}\n" "$group_name"
    # Create new group block
    group_block="# Group: $group_name
    Host ${group_code}-*
      IdentityFile $custom_key_path
      AddKeysToAgent yes"
fi

# Add the new host to the group
host_entry="
    Host $ssh_hostname
      HostName $ip
      User $user"

# Append host entry to the group block
group_block="$group_block
$host_entry"

# Combine the configurations
new_config_content="$new_config_content
$group_block
$config_content
$END_MARKER"

# Now write everything back to the config file
{
  printf "%s\n" "$before_content"
  printf "%s\n" "$new_config_content"
  printf "%s\n" "$after_content"
} > "$SSH_CONFIG_FILE"

display_success "SSH configurations updated successfully."

pause

# Completion Message
display_header
display_success "SSH setup completed successfully!"

# Display final instructions
printf "${MAGENTA}You can now connect to your remote host using the alias:${NC}\n"
printf "\n"
printf "${WHITE}    ssh %s${NC}\n" "$ssh_hostname"
printf "\n"
printf "${GREEN}Enjoy your streamlined SSH experience!${NC}\n"
printf "\n"

# End of the script
