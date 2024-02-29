#!/bin/sh

start_tunnel()
{
    # Stop existing tunnel
    stop_tunnel

    # Create an empty log file
    touch "$log_file"
      
    # Download cloudflared binary if missing
    if [ ! -f "/usr/local/bin/cloudflared" ]; then
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi

    # Start new cloudflared service in the background and redirect its output to a log file
    /usr/local/bin/cloudflared tunnel --no-autoupdate --url "http://localhost:$tunnel_port" >> "$log_file" 2>&1 &
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
    echo "ADDRESS=\"$tunnel_url\"" > "$storage_file"
    echo "PORT=$tunnel_port" >> "$storage_file"
}

read_data()
{
    # Read data from tunnel.cfg, write to tunnel_url and tunnel_port
    . "$storage_file"
    tunnel_url="$ADDRESS"
    tunnel_port="$PORT"
}

# Temporary storage file
storage_file="tunnel.cfg"

# Define the log file path
log_file="/var/log/cloudflared.log"

# Assign $1 to tunnel_port if provided, otherwise use "80"
tunnel_port="${1:-80}"

# Initialize tunnel URL variable
tunnel_url=""


if [ "$1" = "stop" ]; then
    # Call stop_tunnel function
    stop_tunnel
elif [ "$1" -gt 0 ]; then
    # Start new tunnel with provided port
    start_tunnel
    extract_tunnel_url
else
    if [ -f "$storage_file" ]; then
        # Read data from tunnel.cfg
        read_data
        echo "$ADDRESS"
    else 
        # Create new storage file if missing
        start_tunnel
    fi
fi


# Output tunnel address and port if active
if [ -f "$storage_file" ]; then
    echo "$tunnel_url $tunnel_port"
fi
