#!/usr/local/bin/python2.7

###
# This script is responsible for connecting to the Rackspace API
# and polling the servers that are available.  It then dynamically build
# the hadoop master, slave and proxy files that are then pushed out
# via puppet.
###

from cloudservers import CloudServers
import argparse
import tempfile
import os
import re
import sys
import shutil

#define our proxy DNS names
mapred_proxy_dns='mapred-c1.smwa.net'
hdfs_proxy_dns='hdfs-c1.smwa.net'

## setup our cloud connection ##
cloudservers = CloudServers('MYUSER','MYAPI')

## define our hadoop master/slave path defaults
masters_file = '/var/lib/puppet/files/prod/cdh3u0/conf/masters'
masters_file_bak = '/var/lib/puppet/files/prod/cdh3u0/conf/masters.bak'
slaves_file = '/var/lib/puppet/files/prod/cdh3u0/conf/slaves'
slaves_file_bak = '/var/lib/puppet/files/prod/cdh3u0/conf/slaves.bak'
proxy_file = '/var/lib/puppet/files/common/puppetmaster/conf/hadoop-proxy.conf'
proxy_file_bak = '/var/lib/puppet/files/common/puppetmaster/conf/hadoop-proxy.conf.bak'

# create temp files in memory to hold our script
masters_tmp = tempfile.SpooledTemporaryFile(max_size=65535)
slaves_tmp = tempfile.SpooledTemporaryFile(max_size=65535)
proxy_tmp = tempfile.SpooledTemporaryFile(max_size=65535)
all_servers = cloudservers.servers.list()

def main():    
    # fetch our arguments
    # ugly hack since I added support for multiple clusters after the fact
    results = parse_args()
    global mapred_proxy_dns
    global hdfs_proxy_dns
    global masters_file
    global masters_file_bak
    global slaves_file
    global slaves_file_bak
    global proxy_file
    global proxy_file_bak
    mapred_proxy_dns='mapred-%s.smwa.net' % results.cluster_prefix
    hdfs_proxy_dns='hdfs-%s.smwa.net' % results.cluster_prefix
    proxy_file = '/var/lib/puppet/files/common/puppetmaster/conf/hadoop-proxy-%s.conf' % results.cluster_prefix
    proxy_file_bak = '/var/lib/puppet/files/common/puppetmaster/conf/hadoop-proxy-%s.conf.bak' % results.cluster_prefix
    masters_file = '/var/lib/puppet/files/prod/cdh3u0/conf/%s-masters' % results.cluster_prefix
    masters_file_bak = '/var/lib/puppet/files/prod/cdh3u0/conf/%s-masters.bak' % results.cluster_prefix
    slaves_file = '/var/lib/puppet/files/prod/cdh3u0/conf/%s-slaves' % results.cluster_prefix
    slaves_file_bak = '/var/lib/puppet/files/prod/cdh3u0/conf/%s-slaves.bak' % results.cluster_prefix
    # end added suport for multiple clusters

    #poll Rackspace for our servers
    # exit if we have none
    master_exists = False
    for find_master in all_servers:
        if re.search('^%s-m[0-9]{3}.*$' % results.cluster_prefix,find_master.name):
            master_exists = True
    if not master_exists:
        print "No rackapce cluster detected.  Exiting without updating"
        masters_tmp.close()
        slaves_tmp.close()
        sys.exit(1)
   
    #populate our master/slave files
    masters_header() 
    slaves_header() 
    nodelist_rackspace_populate(results.cluster_prefix) 

    #populate our http proxy config
    proxy_header()
    proxy_hdfs_populate(results.cluster_prefix)
    proxy_footer()
    proxy_header()
    proxy_mapred_populate(results.cluster_prefix)
    proxy_footer()
    
    # backup our scripts if it exists
    if os.path.isfile(masters_file):
        shutil.move(masters_file,masters_file_bak)
    if os.path.isfile(slaves_file):
        shutil.move(slaves_file,slaves_file_bak)
    if os.path.isfile(proxy_file):
        shutil.move(proxy_file,proxy_file_bak)
    
    #reset to begining of script file
    masters_tmp.seek(0)
    slaves_tmp.seek(0)
    proxy_tmp.seek(0)

    #write out our masters file
    f = open(masters_file,'wb')
    f.write(masters_tmp.read())
    f.flush()
    f.close()
    masters_tmp.close()

    #write out our slaves file
    g = open(slaves_file,'wb')
    g.write(slaves_tmp.read())
    g.flush()
    g.close()
    slaves_tmp.close()

    #write our our proxy conf file
    h = open(proxy_file,'wb')
    h.write(proxy_tmp.read())
    h.flush()
    h.close()
    proxy_tmp.close()

def nodelist_rackspace_populate(cluster_prefix):
    #loop servers and generate hosts files
    for myserver in all_servers:
        if re.search('^%s-m[0-9]{3}.*$' % cluster_prefix,myserver.name):
            masters_tmp.write("%s\n" %  myserver.name)
        elif re.search('^%s-n[0-9]{3}.*$' % cluster_prefix,myserver.name):
            slaves_tmp.write("%s\n" %  myserver.name)

def slaves_header():
    slaves_tmp.write("## begin hadoop slave hosts ##\n")

def masters_header():
    masters_tmp.write("## begin hadoop master hosts ##\n")

def proxy_mapred_populate(cluster_prefix):
    for myserver in all_servers:
        if re.search('^%s-m[0-9]{3}.*$' % cluster_prefix,myserver.name):
            proxy_tmp.write("ServerName %s\n" % mapred_proxy_dns)
            proxy_tmp.write("<Location / >\n\tAuthType Basic\n\tAuthName \"/\"\n\tAuthUserFile /usr/local/apache2/conf/proxy-htpasswd\n\trequire valid-user\n</Location>\n")
            proxy_tmp.write("ProxyPass / http://%s:50030/\n" % myserver.private_ip)
            proxy_tmp.write("ProxyPassReverse / http://%s:50030/\n" % myserver.private_ip)

def proxy_hdfs_populate(cluster_prefix):
    for myserver in all_servers:
        if re.search('^%s-m[0-9]{3}.*$' % cluster_prefix,myserver.name):
            proxy_tmp.write("ServerName %s\n" % hdfs_proxy_dns)
            proxy_tmp.write("<Location / >\n\tAuthType Basic\n\tAuthName \"/\"\n\tAuthUserFile /usr/local/apache2/conf/proxy-htpasswd\n\trequire valid-user\n</Location>\n")
            proxy_tmp.write("ProxyPass / http://%s:50070/\n" % myserver.private_ip)
            proxy_tmp.write("ProxyPassReverse / http://%s:50070/\n" % myserver.private_ip)
            
def proxy_header():
    proxy_tmp.write("## begin hadoop job/hdfs master node proxy ##\n")
    proxy_tmp.write("<VirtualHost *:80>\n")

def proxy_footer():
    proxy_tmp.write("</VirtualHost>\n")
    

def parse_args():
    """
    Parse arguments and set proper variables
    @param cluster_prefix Prefix for cluster (c1,c2...c9)
    """
    parser = argparse.ArgumentParser(description="Cluster Prefix")
    parser.add_argument('-x', action="store", dest="cluster_prefix", required=True, help="Cluster Preifx (c[0-9]")
    results = parser.parse_args()
    # santize action and listener
    if not re.search('^c[0-9]$',results.cluster_prefix):
        print "ERROR: Invalid Cluster Prefix.  Must be c[0-9]"
        sys.exit(1)
    return results

if __name__ == '__main__':
    main()
