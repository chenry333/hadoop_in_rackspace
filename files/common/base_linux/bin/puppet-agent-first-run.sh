#!/bin/bash

# This runs the pupet agent

### as a first run we need to add our
### puppet master into the hosts file
### then puppet overwrites this file
### with the usual run parameters

MYHOST=puppetmaster.example.com

echo "" >> /etc/hosts
echo "`/usr/local/bin/rackspace_info.py  |grep ${MYHOST} | awk '{print $3}'`  ${MYHOST}" >> /etc/hosts

if [ -f /usr/sbin/puppetd ]; then
    killall -9 puppetd 1>> /dev/null 2>&1
    sleep 5;
        /usr/sbin/puppetd --onetime --no-daemonize --server=${MYHOST}  1>> /dev/null 2>&1
else
        echo "Error - puppet not installed.... this is fatal"
fi
