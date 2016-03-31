#! /usr/bin/env bash
exe=eaglelist_server
go build -o $exe || exit 1
sudo setcap 'cap_net_bind_service=ep' ./$exe || exit 1
# kill the previous server
ps -ef | grep $exe | grep -v grep | awk '{print $2}' | xargs kill -9
# Start a new server, in the background
rm nohup.out
touch nohup.out
nohup ./$exe &
tail -f nohup.out
