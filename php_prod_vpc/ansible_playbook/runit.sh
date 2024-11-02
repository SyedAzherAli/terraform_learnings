#!/bin/bash
# Variables
OLD_KEYPATH="/home/ec2-user/EC2keyPair.pem"
KEY_NAME="id_rsa"  # Default key name
KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Generate SSH key pair
echo "Generating SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""

# Check if ssh-keygen was successful
if [ $? -ne 0 ]; then
    echo "Error generating SSH key."
    exit 1
fi

# Ensure two remote hosts are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <remote_host1> <remote_host2>"
    exit 1
fi

# Copy the SSH key to the specified remote servers
for HOST in "$1" "$2"; do
    echo "Copying SSH key to $HOST..."
    ssh-copy-id -f "-o IdentityFile $OLD_KEYPATH" ec2-user@"$HOST"

    # Check if ssh-copy-id was successful
    if [ $? -eq 0 ]; then
        echo "SSH key copied successfully to $HOST."
    else
        echo "Error copying SSH key to $HOST."
        exit 1
    fi
done
