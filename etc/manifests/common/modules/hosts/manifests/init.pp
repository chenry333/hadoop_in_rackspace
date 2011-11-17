## handles adding all our host to
## the /etc/hosts file

class hosts {

    file {

        "/etc/hosts.d":
            ensure => directory,
            owner  => root,
            group  => root,
            mode   => 700;
    
        "/etc/hosts.d/00_localhost.hosts":
            owner   => root,
            group   => root,
            mode    => 400,
            notify  => Exec["rebuild-hosts.sh"],
            content => "127.0.0.1     localhost localhost.localdomain\n${ipaddress_eth1}     ${fqdn} ${hostname}\n"

    }

    exec {
        "rebuild-hosts.sh":
            command     => "/bin/mv -f /etc/hosts /etc/hosts.bak; /bin/touch /etc/hosts; /bin/cat /etc/hosts.d/* >> /etc/hosts",
            refreshonly => true;
    }
}
