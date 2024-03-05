# tunnel.sh
## _Shell script cloudflared quick tunnels_
Robust shell script to retrieve & manage the "cloudflared" binary, adding basic functionality to control the quick tunnel.<br>
Upon usage, the shell script creates a ```tunnel.cfg``` to store and retrieve the current tunnel URL & Port.<br>
The tunnel logs are being written to ```/var/log/cloudflared.log```.

## Setup
Retrieve the latest tunnel.sh and store it in ```/usr/local/bin/```
```sh
curl https://raw.githubusercontent.com/run2go/tunnel/main/tunnel.sh > /usr/local/bin/tunnel.sh
```

Make tunnel.sh file executable
```sh
chmod +x /usr/local/bin/tunnel.sh
```

Create "tunnel" alias
```sh
alias tunnel='/usr/local/bin/tunnel.sh'
```

## Usage
| _Command_ | _Description_ |
| ------ | ------ |
| ```tunnel``` | Print the current tunnel or create a new one with port 80 |
| ```tunnel <PORT>``` | Create new tunnel with designated port |
| ```tunnel stop``` | Stop a running tunnel |

## License
MIT
