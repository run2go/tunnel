# tunnel.sh
Simple shell script to handle cloudflared quick tunnels.

## Setup
Retrieve the latest tunnel.sh and store it in /usr/local/bin/
```sh
curl https://raw.githubusercontent.com/run2go/tunnel/main/tunnel.sh > /usr/local/bin/tunnel.sh
```

Create "tunnel" alias
```sh
alias tunnel='/usr/local/bin/tunnel.sh'
```

## Usage
Print the current tunnel & port or create new one with port 80
```sh
tunnel
```

Create new tunnel with designated port
```sh
tunnel <PORT>
```

Stop a running tunnel
```sh
tunnel stop
```
