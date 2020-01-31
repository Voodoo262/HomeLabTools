#!/bin/sh

# Cloudflare whitelist script. This script assumes you already have a rule
# in your INPUT chain that causes all http/https traffic to jump to a new
# chain called INPUT_HTTP for further filtering. Every time the script is
# run, it will rebuild the INPUT_HTTP chain

# Get latest Cloudflare IPs
rm -f ips-v4
echo "Downloading newest IP list from Cloudflare..."
wget https://www.cloudflare.com/ips-v4
if [ $? -ne 0 ]; then
    echo "Error downloading IP list"
    exit 1
fi
echo "Download succeeded"

# Purge rules
echo "Purging firewall rules..."
iptables -F INPUT_HTTP

# LAN whitelist
echo "Configuring LAN whitelist..."
iptables -A INPUT_HTTP -p tcp --source=192.168.0.0/16 -j ACCEPT

# Cloudflare whitelist
echo "Configuring Cloudflare whitelist..."
while read p; do
    iptables -A INPUT_HTTP -p tcp --source=$p -j ACCEPT
done < ips-v4

# Default - drop
iptables -A INPUT_HTTP -p tcp -j DROP

# Save
/etc/init.d/iptables save
echo "Done."
