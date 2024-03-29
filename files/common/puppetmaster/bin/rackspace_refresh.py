#!/usr/local/bin/python2.7

###
# This script is responsible for connecting to the Rackspace API
# and polling the servers that are available.  It then dynamically build
# the firewall and hosts files for the core Operating Systems that are
# then pushed out via puppet.
###
from cloudservers import CloudServers
import tempfile
import os
import re
import sys
import shutil

puppetmaster_server='puppetmaster.example.com'

## setup our cloud connection ##
cloudservers = CloudServers('MYUSER','MYAPI')

## define our firewall/hosts paths
firewall_file = '/var/lib/puppet/files/common/base_centos/etc/rackspace_fw.sh'
firewall_file_bak = '/var/lib/puppet/files/common/base_centos/etc/rackspace_fw.sh.bak'
hosts_file = '/var/lib/puppet/files/common/hosts/rackspace.hosts'
hosts_file_bak = '/var/lib/puppet/files/common/hosts/rackspace.hosts.bak'
## hg master server ##
hg_ip="1.1.1.1"
hg_hostname="hg.example.com c1-hg01"

# create temp files in memory to hold our script
fw_script = tempfile.SpooledTemporaryFile(max_size=65535)
hosts_script = tempfile.SpooledTemporaryFile(max_size=65535)
all_servers = cloudservers.servers.list()

def main():    
    #poll Rackspace for our servers
    # exit if we have none
    if len(all_servers) < 1:
        print "No rackapce servers detected.  Exiting without updating"
        fw_script.close()
        sys.exit(1)
   
    #populate our firewall temp file
    fw_header() 
    fw_rackspace_populate() 
    #populate our hosts temp file
    hosts_header() 
    hosts_rackspace_populate() 
    
    # backup our scripts if it exists
    if os.path.isfile(firewall_file):
        shutil.move(firewall_file,firewall_file_bak)
    if os.path.isfile(hosts_file):
        shutil.move(hosts_file,hosts_file_bak)
    
    #reset to begining of script file
    fw_script.seek(0)
    hosts_script.seek(0)

    #write out our firewall file
    f = open(firewall_file,'wb')
    f.write(fw_script.read())
    f.flush()
    f.close()
    fw_script.close()

    #write out our hosts file
    g = open(hosts_file,'wb')
    g.write(hosts_script.read())
    g.flush()
    g.close()
    hosts_script.close()

def hosts_rackspace_populate():
    #loop servers and generate hosts files
    for myserver in all_servers:
        hostname = myserver.name.split('.')[0]
        hosts_script.write("%s      %s %s\n" % (myserver.private_ip, myserver.name, hostname))


def hosts_header():
    hosts_script.write("%s      %s\n" % (hg_ip,hg_hostname))
    hosts_script.write("## begin racksapce hosts ##\n")

def fw_rackspace_populate():
    #loop servers and generate firewall rules
    for myserver in all_servers:
        fw_script.write("## adding rules for %s\n" % myserver.name)
        fw_script.write("$IPT -A INPUT -i $INT -s %s -j ACCEPT\n\n" % myserver.private_ip)

def fw_header():
    ### write our Firewall script header ###
    fw_script.write("#!/bin/bash\n")
    fw_script.write("\n# This file is generated by a python script which polls the rackspace API\n")
    fw_script.write("# Setup our variables\n")
    fw_script.write("IPT=/sbin/iptables\n")
    fw_script.write("EXT=eth0\n")
    fw_script.write("INT=eth1\n")
    fw_script.write("#Flush any existing rules and set default accept just in case\n$IPT -P INPUT ACCEPT\n$IPT -F\n")
    fw_script.write("#Setup Global iptables rules\n")
    fw_script.write("#Loopback is important :)\n$IPT -A INPUT -i lo -j ACCEPT\n")
    fw_script.write("#lets allow established/related connections\n$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n")
    fw_script.write("#lets allow SSH connections - but rate limit\n$IPT -I INPUT -p tcp --dport 22 -i $EXT -m state --state NEW -m recent --set\n")
    fw_script.write("$IPT -I INPUT -p tcp --dport 22 -i $EXT -m state --state NEW -m recent --update --seconds 60 --hitcount 3 -j DROP\n")

    ### Only allow external ssh to infra server ###
    fw_script.write("if [ $HOSTNAME == %s ]; then \n$IPT -A INPUT -p tcp --syn --dport 22 -j ACCEPT\nfi\n" % puppetmaster_server)

    fw_script.write("$IPT -A INPUT -p tcp --syn --dport 80 -j ACCEPT\n")
    fw_script.write("#Lets drop bad stuff\n$IPT -P INPUT DROP\n")
    fw_script.write("\n\n\n")

if __name__ == '__main__':
    main()
