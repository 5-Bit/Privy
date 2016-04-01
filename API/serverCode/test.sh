#! /usr/bin/env bash
go build -o eaglelist
sudo setcap 'cap_net_bind_service=ep' ./eaglelist
# kill the previous server
ps -ef | grep eaglelist | grep -v grep | awk '{print $2}' | xargs kill -9
# Start a new server, in the background
./eaglelist 

