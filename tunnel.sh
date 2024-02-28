#!/bin/sh

start_new_tunnel()
{
    # Remove the existing log file
    rm -f "$log_file"

    # Create an empty log file
    touch "$log_file"

    # Stop any running cloudflared processes
    pkill cloudflared

    # Start cloudflared service in the background and redirect its output to a log file
    /usr/local/bin/cloudflared tunnel --no-autoupdate --url "http://localhost:$tunnel_port" >> "$log_file" 2>&1 &
}

extract_tunnel_url()
{
    # Loop until tunnel information is extracted
    while [ -z "$tunnel_url" ]; do
        # Read the log file line by line
        while IFS= read -r line; do
            # Extract tunnel information from the line
            tunnel_url=$(echo "$line" | grep -o "https://.*trycloudflare.com")
            # If tunnel URL is found, break out of the loop
            [ -n "$tunnel_url" ] && break
        done < "$log_file"
        
        # Wait for 1 second before checking again
        sleep 1
    done
}

store_data()
{
    # Write data to tunnel.cfg
    echo "ADDRESS=\"$tunnel_url\"" > "$temp_file"
    echo "PORT=$tunnel_port" >> "$temp_file"
}

read_data()
{
    # Read data from tunnel.cfg (tunnel_url and tunnel_port)
    . "$temp_file"
}

# Temporary storage file
temp_file="tunnel.cfg"

# Define the log file path
log_file="/var/log/cloudflared.log"

# Assign $1 to tunnel_port if provided, otherwise use "80"
tunnel_port="${1:-80}"

# Initialize tunnel URL variable
tunnel_url=""

# Download cloudflared binary if missing
if [ ! -f "/usr/local/bin/cloudflared" ]; then
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
    echo "Cloudflared binary downloaded and installed."
fi

if [ "$1" = "init" ]; then
    # Create new storage file
    > "$temp_file"
    
    start_new_tunnel
    extract_tunnel_url
    store_data

    # Output tunnel address and port
    echo "$tunnel_url $tunnel_port"
elif [ "$1" -gt 0 ]; then
    # Start new tunnel with provided port
    start_new_tunnel
    extract_tunnel_url
    store_data

    # Output tunnel address and port
    echo "$tunnel_url $tunnel_port"
else 
    # Read data from tunnel.cfg if available
    if [ -f "$temp_file" ]; then
        read_data
        echo "$ADDRESS"
    else
        echo "[offline]"
    fi
fi
