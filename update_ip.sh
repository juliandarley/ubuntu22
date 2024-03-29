#!/bin/bash

## NB. so far, this only works for ubuntu 22 & netplan
## TO START THIS SCRIPT USE & FOLLOW THE PROMPTS
## unless you are doing it on a physically connected terminal or the proxmox vm console, you will inevitably lose connection
## sudo ~/bin/update_ip.sh

# Get the main IP address
IP_ADDRESSES=$(hostname -I)
IP_ARRAY=($IP_ADDRESSES)

if [ ${#IP_ARRAY[@]} -gt 1 ]; then
    echo "Multiple IP addresses found. Please select the main IP address:"
    select ip in "${IP_ARRAY[@]}"; do
        if [[ -n $ip ]]; then
            MAIN_IP=$ip
            break
        else
            echo "Invalid selection."
            exit 1
        fi
    done
else
    MAIN_IP=${IP_ARRAY[0]}
fi

echo "Selected IP: $MAIN_IP"

# Search for the configuration file and exclude backup files
CONFIG_FILES=$(sudo grep -rl "$MAIN_IP" /etc | grep -v "backup")

# Convert the search result into an array
CONFIG_FILES_ARRAY=($CONFIG_FILES)

# If no files are found
if [ ${#CONFIG_FILES_ARRAY[@]} -eq 0 ]; then
    echo "No configuration file found for the IP address. Exiting."
    exit 1
fi

# If more than one file is found or to confirm the file to backup
if [ ${#CONFIG_FILES_ARRAY[@]} -gt 1 ]; then
    echo "Multiple configuration files found. Please select the correct one to backup:"
    select config in "${CONFIG_FILES_ARRAY[@]}"; do
        if [[ -n $config ]]; then
            CONFIG_FILE=$config
            break
        else
            echo "Invalid selection."
            exit 1
        fi
    done
elif [ ${#CONFIG_FILES_ARRAY[@]} -eq 1 ]; then
    CONFIG_FILE=${CONFIG_FILES_ARRAY[0]}
    echo "One configuration file found: $CONFIG_FILE"
else
    echo "No configuration files found. Exiting."
    exit 1
fi

echo "Selected configuration file: $CONFIG_FILE"

# Confirm with the user
read -e -i "y" -p "Are you sure you want to backup this file? [Y/n]: " confirmation
confirmation=${confirmation:-y}
if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    echo "Backup cancelled."
    exit 1
fi

# Validate that CONFIG_FILE is not empty and exists
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file path is invalid or file does not exist. Exiting."
    exit 1
fi

# Proceed with the backup, ensuring full path is displayed
BACKUP_FILE="$(dirname "$CONFIG_FILE")/$(basename "$CONFIG_FILE").backup_$(date +%Y%m%d%H%M%S)"
echo "Creating backup of the configuration file at: $BACKUP_FILE"
sudo cp "$CONFIG_FILE" "$BACKUP_FILE" && echo "Backup successfully created at: $BACKUP_FILE" || echo "Failed to create backup."

# Offer the current IP as a placeholder and default to changing the IP address
echo "Current IP is $MAIN_IP. Enter the new IP address (or press Enter to keep $MAIN_IP):"
read -e -i "$MAIN_IP" -p "New IP Address: " INPUT
NEW_IP=${INPUT:-$MAIN_IP}

# Extract the current gateway
CURRENT_GATEWAY=$(grep -A 3 "routes:" "$CONFIG_FILE" | grep "via" | awk '{print $2}')
echo "Current gateway is $CURRENT_GATEWAY"

# Assume the user does not want to change the gateway by default
read -e -i "" -p "Do you want to change the gateway? (y/N): " CHANGE_GATEWAY
CHANGE_GATEWAY=${CHANGE_GATEWAY:-n}

if [[ $CHANGE_GATEWAY =~ ^[Yy]$ ]]; then
    echo "Enter the new gateway (or press Enter to keep $CURRENT_GATEWAY):"
    read -e -i "$CURRENT_GATEWAY" -p "New Gateway: " INPUT
    NEW_GATEWAY=${INPUT:-$CURRENT_GATEWAY}
    # Use sed to replace the gateway
    sudo sed -i "/via/c\        via: $NEW_GATEWAY" "$CONFIG_FILE"
    ## sudo sed -i "/- to: default/a\        via: $NEW_GATEWAY" "$CONFIG_FILE"
fi

# Use sed to replace the first IP address in the addresses list
# This command is safer but assumes the file is properly indented
sudo sed -i "0,/      - $MAIN_IP/{s|      - $MAIN_IP|      - $NEW_IP|}" "$CONFIG_FILE"

# Apply changes with netplan
sudo netplan apply 2> >(grep -v 'ovsdb-server.service is not running' >&2)
echo "ip data is being updated. you may lose contact with this console."

## THE FOLLOWING WILL ONLY SHOW UP IF DONE IN A CONSOLE PERMANENTLY CONNECTED TO THE MACHINE LIKE A PHYSICAL MONITOR OR THE CONSOLE IN PROXMOX

# Confirm the new IP address is working
## NEW_IP_ADDRESSES=$(hostname -I)
## echo "New IP addresses: $NEW_IP_ADDRESSES"

# Verify connectivity
## ping -c 3 8.8.8.8


