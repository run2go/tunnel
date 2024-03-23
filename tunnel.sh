#!/bin/bash

# Define file locations
storage_file="/usr/local/bin/tunnel.cfg"
log_file="/var/log/cloudflared.log"

# Define default target address & port variables
target_address="127.0.0.1"
target_port="80"

# Invoke sudo usage if missing
if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo "$0" "$@"
    exit $?
fi

# Define binary url
binary_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-"

if [[ "$(arch)" -eq "armv7l" ]]; then
    binary_url="${binary_url}arm"
else
    binary_url="${binary_url}amd64"
fi

start_tunnel() {
    # Stop existing tunnel
    stop_tunnel

    # Create an empty log file
    touch "$log_file"

    # Create an empty storage file
    touch "$storage_file"

    # Download cloudflared binary if missing
    if [ ! -f "/usr/local/bin/cloudflared" ]; then
        wget -q "$binary_url" -O /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi

    # Start new cloudflared service in the background and redirect its output to a log file
    /usr/local/bin/cloudflared tunnel --no-autoupdate --url "$target" >> "$log_file" 2>&1 &

    # Extract tunnel URL
    extract_tunnel_url

    # Store extracted data
    store_data
}

stop_tunnel() {
    # Stop any running cloudflared processes
    pkill cloudflared

    # Remove temporary storage file
    rm -f "$storage_file"

    # Remove the existing log file
    rm -f "$log_file"
}

extract_tunnel_url() {
    # Loop until tunnel information is extracted
    while [ -z "$tunnel" ]; do
        # Read the log file line by line
        while IFS= read -r line; do
            # Check if the line contains "failed" before trycloudflare.com URL
            if [[ "$line" =~ failed ]]; then
                echo "Error: $line"
                exit 1
            fi
            
            # Extract tunnel information from the line
            tunnel=$(echo "$line" | grep -o "https://.*trycloudflare.com")

            # If tunnel URL is found, break out of the loop
            [ -n "$tunnel" ] && break
        done < "$log_file"

        # Wait for 0.1 second before checking again
        sleep 0.1
    done
}

store_data() {
    # Write data to tunnel.cfg
    echo "$tunnel" > "$storage_file"
}

read_data() {
    # Read data from tunnel.cfg and write to tunnel
    tunnel=$(cat "$storage_file")
}

# Call stop_tunnel function
if [[ "$1" = "stop" ]]; then
    stop_tunnel
    exit 0
# Use localhost + port if only port provided
elif [[ "$1" =~ ^([0-9]+)$ ]]; then
    target="localhost:$1"
# Use provided address
elif [[ "$1" ]]; then
    target="$1"
# Else use default parameters
else
    target="$target_address:$target_port"
fi

# Start a new tunnel
if [[ "$1" ]] || [[ ! -f "$storage_file" ]]; then
    start_tunnel
# Read data from tunnel.cfg
else
    read_data
fi

# Output tunnel address
echo "$tunnel"
exit 0
