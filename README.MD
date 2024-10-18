# super-simple-ssh
## Overview

Automate the setup of SSH configurations for password-less authentication through the use of **SSH keys and custom SSH aliases**. Streamline the process of selecting an SSH key, adding it to the SSH agent, copying the key to a remote host, and updating the SSH configuration file (`~/.ssh/config`) with the necessary settings to reduce friction and increase accessibility.

This tool is particularly useful in adolescent network environments like school and home labs, where DNS is not yet configured to service SSH connections. 

## Demo

![super-simple-ssh Demo](assets/auth.gif)
*User demonstrating access to a lab machine @ mach 1 speed.*
## Features

- **SSH Key Management**: Use an existing SSH key or generate a new one with your choice of algorithm (RSA, ECDSA, or Ed25519).
- **SSH Agent Integration**: Automatically adds your SSH key to the `ssh-agent` for seamless authentication.
- **Remote Host Configuration**: Copies your SSH public key to the remote host for password-less authentication.
- **SSH Config File Management**: Updates your `~/.ssh/config` file with organized and sorted host configurations.
- **TUI**: Provides clear instructions and feedback throughout the setup process.
  
