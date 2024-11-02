#!/bin/bash

# Update the package index
sudo yum update -y

# Install the EPEL repository
sudo yum install epel-release -y

# Install Ansible
sudo yum install ansible -y

# Verify the installation
ansible --version

echo "Ansible has been installed successfully."
