#!/bin/bash

# Log file and password storage file
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Function to log messagesS
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check if the input file is provided 
if [ $# -eq 0 ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

# Check if the input file exists
if [ ! -f $1 ]; then
    echo "Error: File $1 not found!"
    exit 1
fi

# Ensure the secure directory and files exist
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Remove leading and trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create the user with the same group name
    if id -u "$username" >/dev/null 2>&1; then
        log_message "User $username already exists"
    else
        useradd -m -g "$username" -s /bin/bash "$username"
        log_message "User $username created with primary group $username"
        
        # Set up home directory permissions
        chmod 700 /home/$username
        chown $username:$username /home/$username
        
        # Generate a random password
        password=$(openssl rand -base64 12)
        echo "$username:$password" | chpasswd
        
        # Log the password securely
        echo "$username,$password" >> $PASSWORD_FILE
        log_message "Password for user $username set and stored securely"
    fi

    # Add user to additional groups
    IFS=',' read -ra additional_groups <<< "$groups"
    for group in "${additional_groups[@]}"; do
        group=$(echo "$group" | xargs)
        
        if [ $(getent group "$group") ]; then
            usermod -aG "$group" "$username"
            log_message "User $username added to group $group"
        else
            groupadd "$group"
            usermod -aG "$group" "$username"
            log_message "Group $group created and user $username added"
        fi
    done
done < "$1"

# End of script
