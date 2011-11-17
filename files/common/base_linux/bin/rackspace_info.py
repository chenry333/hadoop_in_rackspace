#!/usr/local/bin/python2.7

from cloudservers import CloudServers
import tempfile
import os
import re
import sys
import shutil

cloudservers = CloudServers('MYUSER','MYAPI')

all_servers = cloudservers.servers.list()
for my_server in  all_servers:
    print ("%s - %s - %s" % (my_server.name,my_server.private_ip,my_server.public_ip))
