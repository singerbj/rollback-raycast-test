#!/bin/bash

# Reset dummynet to default config
sudo dnctl -f flush

# Compose an addendum to the default config: creates a new anchor
(cat /etc/pf.conf &&
  echo 'dummynet-anchor "my_anchor"' &&
  echo 'anchor "my_anchor"') | sudo pfctl -q -f -

# Configure the new anchor
cat <<EOF | sudo pfctl -q -a my_anchor -f -
dummynet in  proto tcp from any to 127.0.0.1 port 9999 pipe 1
dummynet out proto tcp from any to 127.0.0.1 port 9999 pipe 1
dummynet in  proto udp from any to 127.0.0.1 port 9999 pipe 1
dummynet out proto udp from any to 127.0.0.1 port 9999 pipe 1
EOF

# Create the dummynet queue
sudo dnctl pipe 1 config plr 0.3 bw 100Kbit/s delay 25

# Activate PF
sudo pfctl -E
