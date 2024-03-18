# PowerShell equivalent of the tunnel.sh shell script

function Start-Tunnel {
    # Stop existing tunnel
    Stop-Tunnel

    # Create an empty log file
    New-Item -Path $logFile -ItemType File -Force > $null

    # Create an empty storage file
    New-Item -Path $storageFile -ItemType File -Force > $null

    # Download cloudflared binary if missing
    if (-not (Test-Path $cloudflaredExe)) {
        Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cloudflaredExe
    }

    # Start new cloudflared service in the background and redirect its output to a log file
    Start-Process -FilePath $cloudflaredExe -ArgumentList "tunnel --no-autoupdate --logfile=$logFile --url=$target" -WindowStyle hidden
    
    # Extract tunnel URL
    Extract-Tunnel-Url
}

function Stop-Tunnel {
    # Stop any running cloudflared processes
    try {
        Stop-Process -Name cloudflared -Force -ErrorAction Stop > $null
    } catch {
        # Ignore errors
    }

    # Remove temporary storage file
    try {
        Remove-Item -Path $storageFile -Force -ErrorAction Stop > $null
    } catch {
        # Ignore errors
    }

    # Remove the existing log file
    try {
        Remove-Item -Path $logFile -Force -ErrorAction Stop > $null
    } catch {
        # Ignore errors
    }
}

function Extract-Tunnel-Url {
    # Loop until tunnel information is extracted
    while (-not $tunnel) {
        # Read the log file line by line
        try {
            $lines = Get-Content -Path $logFile -ErrorAction Stop
            foreach ($line in $lines) {
                # Check if the line contains "failed" before extracting the tunnel URL
                if ($line -match "failed") {
                    Write-Output "Error: $line"
                    exit
                }
                # Extract tunnel URL from the line using a regex pattern
                if ($line -match '(https://[^ ]*trycloudflare\.com)') {
                    $tunnel = $matches[0]
                    Store-Data
                    Read-Data
                    break
                }
            }
        } catch {
            Write-Output "Error: $_"
            # Ignore errors
        }

        # Wait for 0.1 second before checking again
        Start-Sleep -Milliseconds 100
    }
}




function Store-Data {
    # Write data to tunnel.cfg
    try {
        $tunnel | Out-File -FilePath $storageFile -Force -ErrorAction Stop > $null
    } catch {
        # Ignore errors
    }
}

function Read-Data {
    # Read data from tunnel.cfg and write to tunnel
    try {
        $tunnel = Get-Content -Path $storageFile -ErrorAction Stop
        Write-Output $tunnel
    } catch {
        # Ignore errors
    }
}

# Define cloudflared binary
$cloudflaredExe = "C:\tunnel\cloudflared.exe"

# Define the log file destination
$logFile = "C:\tunnel\cloudflared.log"

# Define temporary storage file
$storageFile = "C:\tunnel\tunnel.cfg"

# Initialize tunnel variable
$tunnel = $null

# Check if the provided transfer parameter is a number (port)
if ($args[0] -match "^\d+$") {
    $target = "127.0.0.1:$($args[0])"  # Append provided port to localhost
} elseif ($args[0]) {
    $target = $args[0]  # Use provided target address
} else {
    $target = "127.0.0.1:80"  # Default target address and port
}

if ($args[0]) {
    if ($args[0] -eq "stop") {
        # Handle transfer parameter "stop", call Stop-Tunnel function
        Stop-Tunnel
        exit
    } elseif ($args[0] -gt 0) {
        # Start new tunnel with provided target
        Start-Tunnel
    }
} else {
    if (Test-Path $storageFile) {
        # Read data from tunnel.cfg
        Read-Data
    } else {
        # Create new storage file if missing
        Start-Tunnel
    }
}

# Output tunnel address
Write-Output $tunnel
