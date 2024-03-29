#!/bin/bash

# Check if Git is installed
if ! command -v git &> /dev/null
then
    echo "Git is not installed. Please install Git and rerun this script."
    exit 1
fi

# Set your Git global username
git config --global user.name "Julian Darley"

# Set your Git global email
git config --global user.email "julian@merlin-ai.com"

# Change the default branch name from master to main
git config --global init.defaultBranch main

echo "Git username, email, and default branch name have been configured."

