#!/usr/bin/env bash

export GODOT_DEV_ENV=true

./stop_all.sh

logs_folder=`pwd`/logs
mkdir -p $logs_folder

number_of_clients=$1
if [ "$number_of_clients" == "" ]; then
    number_of_clients=1
fi

cd client
for i in $(seq 1 $number_of_clients);
do
    echo "Starting client $i"
    godot $@ > $logs_folder/client-$i.log 2>&1 &
    echo $! >> ../.godot_pids
    sleep 1
done
