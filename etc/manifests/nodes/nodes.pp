### Regex control of what modules are applied ###


if $hostname =~ /^puppetmaster$/ {
    include ssh,
            httpd,
            cloudfuse,
            puppetmaster,
            hosts::rackspace,
            pup_users::hadoop,
            rackspace-firewall,
            sudoers::puppetmaster
}
if $hostname =~ /^hadoop-template$/ {
    include ssh,
            cdh3u0,
            cloudservers,
            sudoers::hadoop,
            pup_users::hadoop,
            rackspace-firewall
}
if $hostname =~ /^c[0-9]-n[0-9]{3}$/ {
   include hosts::rackspace,
           cdh3u0,
           pup_users::hadoop,
           sudoers::hadoop,
           rackspace-firewall
}
if $hostname =~ /^c[0-9]-m[0-9]{3}$/ {
   include hosts::rackspace,
           cdh3u0,
           sudoers::hadoop,
           rackspace-firewall,
           pup_users::hadoop
}



#####
## apply base OS settings common to ALL installs
#####
case $kernel {
    Linux: {
        include base_linux
    }
}
#####
## Apply OS Specific stuff
#####
case $operatingsystem {
    CentOS: { 
        case $operatingsystemrelease {
                5.5: { include base_centos }
        }
    }
}
