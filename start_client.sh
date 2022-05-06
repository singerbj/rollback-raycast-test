#!/usr/bin/env bash

export GODOT_DEV_ENV=true

./stop_all.sh

logs_folder=`pwd`/logs
mkdir -p $logs_folder

cd client

echo "Starting client $i"
godot $@ > $logs_folder/client-$i.log 2>&1 &
echo $! >> ../.godot_pids
