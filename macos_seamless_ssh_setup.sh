#!/bin/bash

echo "Checking for existing SSH keys..."

# Prompt the user for the key algorithm using numeric selection
echo "Select the algorithm for the SSH key:"
echo "1) RSA (Recommended, secure)"
echo "2) ECDSA (Elliptic Curve DSA)"
echo "3) Ed25519 (Modern, fast, and secure)"
read -p "Enter your choice (1/2/3): " algo_choice

case $algo_choice in
    1 ) key_type="rsa -b 4096"; key_algorithm="rsa";;
    2 ) key_type="ecdsa -b 521"; key_algorithm="ecdsa";;
    3 ) key_type="ed25519"; key_algorithm="ed25519";;
    * ) echo "Invalid selection. Exiting script."; exit 1;;
esac

# Use the default SSH file path and offer the user to specify a different one
default_key_path="$HOME/.ssh/id_$key_algorithm"
echo "The default file path for your SSH key will be '$default_key_path'."
read -p "Press Enter to confirm or specify a different path: " custom_key_path
custom_key_path=${custom_key_path:-$default_key_path}

# Prompt for passphrase
echo "You can secure your SSH key with a passphrase (recommended)."
read -s -p "Enter passphrase (leave empty for no passphrase): " passphrase
echo

# Additional ssh-keygen options
echo "You may specify an email for your SSH key (optional)."
read -p "Enter email (leave empty if not desired): " email
ssh_keygen_options=""
if [ ! -z "$email" ]; then
    ssh_keygen_options="-C \"$email\""
fi

# Confirm before generating the SSH key
echo "Ready to generate SSH key with the following options:"
echo "Algorithm: $key_algorithm"
echo "Path: $custom_key_path"
echo "Passphrase: [hidden]"
echo "Email: $email"
read -p "Proceed? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "SSH key generation cancelled. Exiting script."
    exit 1
fi

# Generate the SSH key
if ! ssh-keygen -t $key_type -f "$custom_key_path" -N "$passphrase" $ssh_keygen_options; then
    echo "Failed to generate the SSH key. Exiting script."
    exit 1
fi
echo "New SSH key pair generated at $custom_key_path."

# Adding the SSH private key to the ssh-agent
if ! ssh-add "$custom_key_path"; then
    echo "Failed to add SSH key to ssh-agent. Exiting script."
    exit 1
fi
echo "SSH private key added to the ssh-agent."

# Validate IP address and username
read -p "Enter the username for your host: " user
read -p "Enter the IP address of your host: " ip

if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address format. Exiting script."
    exit 1
fi

echo "Username and IP address recorded."

# Copy the SSH key to the host
if ! ssh-copy-id -i "${custom_key_path}.pub" ${user}@${ip}; then
    echo "Failed to copy the SSH key to the host. Exiting script."
    exit 1
fi
echo "SSH key copied to the host."

# Hostname for SSH configuration
read -p "Enter a preferred hostname for the SSH configuration (e.g., kali-vm): " ssh_hostname

# Check if SSH config file exists and append configuration
if [ ! -f ~/.ssh/config ]; then
    echo "SSH config file does not exist. Creating it now..."
    touch ~/.ssh/config
fi

echo -e "\nHost $ssh_hostname\n  HostName $ip\n  User $user\n  AddKeysToAgent yes\n  IdentityFile $custom_key_path" >> ~/.ssh/config

echo "SSH configuration for $ssh_hostname has been added to your SSH config file."
echo "Setup complete."

