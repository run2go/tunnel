#!/bin/bash

start_tunnel()
{
    # Stop existing tunnel
    stop_tunnel

    # Create an empty log file
    touch "$log_file"

    # Create an empty storage file
    touch "$storage_file"

    # Download cloudflared binary if missing
    if [ ! -f "/usr/local/bin/cloudflared" ]; then
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi

    # Start new cloudflared service in the background and redirect its output to a log file
    /usr/local/bin/cloudflared tunnel --no-autoupdate --url "http://$tunnel_address:$tunnel_port" >> "$log_file" 2>&1 &

    # Extract tunnel URL
    extract_tunnel_url
}

stop_tunnel()
{
    # Stop any running cloudflared processes
    pkill cloudflared

    # Remove temporary storage file
    rm -f "$storage_file"

    # Remove the existing log file
    rm -f "$log_file"
}

extract_tunnel_url()
{
    # Loop until tunnel information is extracted
    while [ -z "$tunnel" ]; do
        # Read the log file line by line
        while IFS= read -r line; do
            # Extract tunnel information from the line
            tunnel=$(echo "$line" | grep -o "https://.*trycloudflare.com")
            # If tunnel URL is found, break out of the loop
            [ -n "$tunnel" ] && break
        done < "$log_file"

        # Wait for 0.1 second before checking again
        sleep 0.1
    done

    # Store extracted data
    store_data
}

store_data()
{
    # Write data to tunnel.cfg
    echo "$tunnel" > "$storage_file"
}

read_data()
{
    # Read data from tunnel.cfg and write to tunnel
    tunnel=$(cat "$storage_file")
}

# Invoke sudo usage if missing
if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
    exit $?
fi

# Define temporary storage file
storage_file="/usr/local/bin/tunnel.cfg"

# Define the log file destination
log_file="/var/log/cloudflared.log"

# Initialize tunnel variable
tunnel=""

# Parse input arguments
if [[ "$1" =~ ^[0-9]+$ ]]; then
    # Port is provided
    tunnel_address="localhost"
    tunnel_port="$1"
elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    # IP address with port is provided
    tunnel_address="${1%:*}"
    tunnel_port="${1##*:}"
elif [[ "$1" =~ ^[^:]+:[0-9]+$ ]]; then
    # Domain name with port is provided
    tunnel_address="${1%:*}"
    tunnel_port="${1##*:}"
else
    # Default to localhost:80 if no valid input provided
    tunnel_address="localhost"
    tunnel_port="80"
fi

if [ "$1" ]; then
    if [ "$1" = "stop" ]; then
        # Handle transfer parameter "stop", call stop_tunnel function
        stop_tunnel
        exit 0
    elif [[ "$tunnel_port" =~ ^[0-9]+$ ]]; then
        # Start new tunnel with provided address and port
        start_tunnel
    else
        echo "Invalid input. Please provide a valid port number or domain name/IP address with port."
        exit 1
    fi
else
    if [ -f "$storage_file" ]; then
        # Read data from tunnel.cfg
        read_data
    else
        # Create new storage file if missing
        start_tunnel
    fi
fi

# Output tunnel address
echo "$tunnel"
