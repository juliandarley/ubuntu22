#!/bin/bash

# Load the .env file
if [ -f ".env" ]; then
    export $(cat .env | xargs)
else 
    echo ".env file not found. Please ensure it exists in the same directory as this script."
    exit 1
fi

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install Git and rerun this script."
    exit 1
fi

# Set your Git global username
git config --global user.name "$NAME"

# Set your Git global email
git config --global user.email "$EMAIL"

# Change the default branch name from master to main
git config --global init.defaultBranch main

echo "Git has been configured with username: '$NAME', email: '$EMAIL', and default branch name: 'main'."

