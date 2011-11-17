#!/bin/bash

MYHOST=puppetmaster.example.com

# This runs the pupet agent
if [ -f /usr/sbin/puppetd ]; then
    killall -9 puppetd 1>> /dev/null 2>&1
    sleep 5;
        /usr/sbin/puppetd --onetime --no-daemonize --server=${MYHOST}  1>> /dev/null 2>&1
else
        echo "Error - puppet not installed.... this is fatal"
fi
