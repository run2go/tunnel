# PowerShell Equivalent of the tunnel.sh Bash Script

function Start-Tunnel {
    # Stop existing tunnel
    Stop-Tunnel

    # Create an empty log file
    New-Item -Path $logFile -ItemType File -Force | Out-Null

    # Create an empty storage file
    New-Item -Path $storageFile -ItemType File -Force | Out-Null

    # Download cloudflared binary if missing
    if (-not (Test-Path $cloudflaredExe)) {
        Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cloudflaredExe
    }

    # Start new cloudflared service in the background and redirect its output to a log file
    Start-Process -FilePath $cloudflaredExe -ArgumentList "tunnel --no-autoupdate --logfile=$logFile --url=http://localhost:$tunnelPort" -NoNewWindow
    
    # Extract tunnel URL
    Extract-Tunnel-Url
}

function Stop-Tunnel {
    # Stop any running cloudflared processes
    Stop-Process -Name cloudflared -Force

    # Remove temporary storage file
    Remove-Item -Path $storageFile -Force

    # Remove the existing log file
    Remove-Item -Path $logFile -Force
}

function Extract-Tunnel-Url {
    # Loop until tunnel information is extracted
    while (-not $tunnel) {
        # Read the log file line by line
        Get-Content -Path $logFile | ForEach-Object {
            # Extract tunnel information from the line
            $tunnel = ($_ -split "https://.*trycloudflare.com")[1]
            # If tunnel URL is found, break out of the loop
            if ($tunnel) { break }
        }

        # Wait for 0.1 second before checking again
        Start-Sleep -Milliseconds 100
    }

    # Store extracted data
    Store-Data
}

function Store-Data {
    # Write data to tunnel.cfg
    $tunnel | Out-File -FilePath $storageFile -Force
}

function Read-Data {
    # Read data from tunnel.cfg and write to tunnel
    $tunnel = Get-Content -Path $storageFile
}

# Define cloudflared binary
$cloudflaredExe = "C:\tunnel\cloudflared.exe"

# Define the log file destination
$logFile = "C:\tunnel\cloudflared.log"

# Define temporary storage file
$storageFile = "C:\tunnel\tunnel.cfg"

# Initialize tunnel variable
$tunnel = ""

# Assign $args[0] to tunnelPort if provided, otherwise use "80"
if ($args[0]) {
    $tunnelPort = $args[0]
} else {
    $tunnelPort = 80
}

if ($args[0]) {
    if ($args[0] -eq "stop") {
        # Handle transfer parameter "stop", call Stop-Tunnel function
        Stop-Tunnel
        exit
    } elseif ($args[0] -gt 0) {
        # Start new tunnel with provided port
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
