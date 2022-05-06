#!/usr/bin/env bash

# reset the firewall
sudo pfctl -F all -f /etc/pf.conf

# remove the limiting network pipe
sudo dnctl -q flush

# disable the firewall
sudo pfctl -d