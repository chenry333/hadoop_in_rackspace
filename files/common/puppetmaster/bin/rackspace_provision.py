#!/usr/local/bin/python2.7
##
# This helps you provision a hadoop cluster!
##
import os
import re
import sys
import time
import getopt
from cloudservers import CloudServers

cloudservers = CloudServers('MYUSER','MYAPI')

def main(argv):
    """
        Our main dummy method.  Calls appropriate helper methods
        @param options - array of command line options
        @method create_cluster - calls create_cluster method
        @method destroy_cluster - calls destroy_cluster method
    """

    # set command line arguments
    options = setopts(argv) 

    # set cluster naming convention
    # this allows multiple clusters with cX prefix
    cluster_prefix='%s' % (options['prefix'])
    cluster_master='%s-m001%s' % (options['prefix'],options['suffix'])
    cluster_node_prefix='%s-n' % options['prefix']
    ## end multiple cluster config addition

    # create our cluster
    if options['command'] == "create":
        create_cluster(cluster_size=options['cluster_size'],
        flavor_id=options['flavor_id'],
        image_id=options['image_id'],
        root_password=options['root_password'],
        cluster_master=cluster_master,
        cluster_node_prefix=cluster_node_prefix,
        cluster_suffix=options['suffix'])

    ## destroy our cluster ##
    elif options['command'] == "destroy":
        destroy_cluster(cluster_master,options['prefix'],cluster_node_prefix,options['suffix'])
    
    ## bad command... exit out ##
    else:
        print "ERROR - incorrect command"
        usage()
        sys.exit(1)

    ## after we destroy or create the clusters lets update our
    ## puppet firewall/hadoop files
    print "Updating infrastructure files (firewall, hosts, hadoop configs)..."
    time.sleep(10)
    os.system("/usr/local/bin/rackspace_refresh.py;/usr/local/bin/rackspace_refresh_hadoop.py -x %s" % options['prefix'])
    os.system("/usr/local/sbin/puppet-agent-run.sh")
    print "Finished Updating infrastructure files"

def check_existing(cluster_master,cluster_node_prefix,cluster_suffix):
    """ 
    Check to make sure we don't already have a hadoop cluster running 
    """
    try:
        if cloudservers.servers.find(name=cluster_master):
            print "ERROR - Server %s already exists - I cannot provision a new one" % cluster_master
            print ""
            return True
        else: 
            for nodes in range(cluster_size):
                current_node="%s%03d%s" % (cluster_node_prefix,nodes,cluster_suffix)
                if cloudservers.servers.find(name=current_node):
                    print "ERROR - Server %s already exists - I cannot provision a new one" % current_node
                    print ""
                    return True
    except:
        return False

def cluster_set_root(server_id,newpassword):
    """
    Use to set the root password for a specific server by node id
    @param server_id - Rackspace ID of the server
    @param newpassword - Password to set the root account to use
    """
    cloudservers.servers.update(server_id,password=newpassword)

def create_cluster(cluster_size,flavor_id,image_id,root_password,cluster_master,cluster_node_prefix,cluster_suffix):
    """ Creates our cluster of size cluster_size """
    if not check_existing(cluster_master,cluster_node_prefix,cluster_suffix):
        print "Creating a cluster of size %d" % (cluster_size)
        print "Creating master node %s..." % cluster_master
        try:
            cloudservers.servers.create(name=cluster_master,image=image_id,flavor=flavor_id)
            print "Successfully created %s" % cluster_master
        except Exception, e:
            print "ERROR Provisioning %s with error: %s" % (cluster_master,e)
            sys.exit(1)

        print "Beginning to provision nodes 1-%d" % cluster_size
        for server_no in range(cluster_size):
            node_name="%s%03d%s" % (cluster_node_prefix,server_no+1,cluster_suffix)
            print "Provisioning %s..." % node_name
            try:
                cloudservers.servers.create(name=node_name,image=image_id,flavor=flavor_id)
                time.sleep(10)
                print "Successfully created %s" % node_name
            except Exception, e:
                print "ERROR Provisioning %s with error: %s" % (cluster_master,e)
                sys.exit(1)
            

def destroy_cluster(cluster_master,cluster_prefix,cluster_node_prefix,cluster_suffix):
    """ This destroys EVERY node in the cluster! """

    print "WARNING - I'm about to delete the following nodes in 30s.  Press CTRL+C to cancel this!!"
    for server in cloudservers.servers.list():
        if re.search('^%s-(m|n)[0-9]{3}.*$' % cluster_prefix,server.name):
            print "%s - %s" % (server.id,server.name)
    time.sleep(30)

    # begin destroying cluster
    print "DESTROYING cluster with master node %s" % cluster_master
    # delete master node
    try:
        print "Deleting master node %s...." % cluster_master
        cloudservers.servers.delete(cloudservers.servers.find(name=cluster_master))
        print "Successfully deleted master node %s" % cluster_master
        print "removing puppet certificate for %s" % cluster_master
        os.system("/usr/sbin/puppetca -c %s" % cluster_master)
    except Exception, e:
        print "ERROR Deleting %s with errors: %s" % (cluster_master,e)
        sys.exit(1)
    # delete slave nodes
    for server_no in range(999):
        node_name="%s%03d%s" % (cluster_node_prefix,server_no+1,cluster_suffix)
        try:
            cloudservers.servers.delete(cloudservers.servers.find(name=node_name))
            print "Deleting %s..." % node_name
            time.sleep(1)
            print "Successfully deleted node %s" % node_name
            print "removing puppet certificate for %s" % node_name
            os.system("/usr/sbin/puppetca -c %s" % node_name)
        except Exception, e:
            if re.search('^No Server matching.*',"%s" % e):
                break
            else:
                print "ERROR Deleting %s with errors: %s" % (node_name,e)
                sys.exit(1)

def setopts(argv):
    """ 
        @return options - array of all the options passed to the script
        @param help - flag to display help
        @param command - command to run (either create or destroy)
        @param size - size of the cluster (must be int)
        @param flavor - flavor of VM to create within RackSpace
        @param image - base image template to provision VM with
        @param pass - default root password for servers
    """


    options={'root_password': "",'prefix':"c1",'suffix': ".example.com"}
    ## use getopt to set our parameters ##
    try:
        opts, args = getopt.getopt(argv, "hc:x:s:f:i:p", ["help","command","prefix","size","flavor","image","pass"])
    except getopt.GetoptError, err:
        print "ERROR: %s" % err
        usage()
        sys.exit(1)

    for o, a in opts:
        if o in ("-h", "--help"):
            print "-h or --help invoked"
            usage()
            sys.exit(0)
        elif o in ("-c", "--command"):
            options['command'] = a
        elif o in ("-s", "--size"):
            try:
                if a.isdigit() == True:
                    options['cluster_size'] = int(a)
                else:
                    print "Cluster Size must be an Integer"
                    usage()
            except: 
                print "Cluster Size must be an Integer"
                usage()
        elif o in ("-f", "--flavor"):
            try:
                if a.isdigit() == True:
                    options['flavor_id'] = int(a)
                else:
                    print "Flavor must be an Integer"
                    usage()
            except: 
                print "Flavor must be an Integer"
                usage()
        elif o in ("-i", "--image"):
            try:
                if a.isdigit() == True:
                    options['image_id'] = int(a)
                else:
                    print "Image must be an Integer"
                    usage()
            except: 
                print "Image must be an Integer"
                usage()
        elif o in ("-p", "--pass"):
            options['root_password'] = a
        elif o in ("-x", "--prefix"):
            if re.search('^c[0-9]{1}$',a):
                options['prefix'] = a
            else:
                print "ERROR: Server Prefix must be in the form cX where x is 0-9"
                usage()
                sys.exit(1)
        else:
            print "Unknown option used"
            usage()
            sys.exit(1)

    ## sanitzie the inputs ##

    try:
        if options['command'] == "create":
            options['cluster_size']
            options['command']
            options['flavor_id']
            options['image_id']
            options['prefix']
    except Exception, e:
        print "ERROR - incorrect command line options"
        usage()
        sys.exit(1)
    ## end parsing options ##
        
    return options


def usage():
    time.sleep(2)
    """Print out how to call hit script"""
    print "./rackspace_provision.py  [-h] -c <create|destroy> -x <prefix> -s <cluster_size> -f <node_flavor_id> -i <image_id> -p =<root_password>\n"
    print "./rackspace_provision.py [--help] --command=<create|destroy> --prefix=<prefix> --size=<cluster_size> --flavor=<node_flavor_id> --image=<image_id> --pass=<root_password>\n"
    print "ie: ./rackspace_provision -c create -x c1 -s 10 -f 4 -i 11689668 -p mypassword"
    print "---------------------"
    print "Current Node Flavors:"
    for flavors in cloudservers.flavors.list():
        print ("%s - %s" % (flavors.id,flavors.name))

    print "----------------------------"
    print "Current Available Images:"
    for images in cloudservers.images.list():
        print ("%s - %s" % (images.id,images.name))
    sys.exit(1)


if __name__ == '__main__':
    main(sys.argv[1:])
