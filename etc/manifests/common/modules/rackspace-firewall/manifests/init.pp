class rackspace-firewall {
    
    file {


        "/etc/init.d/rc.firewall":
            owner  => root,
            group  => root,
            mode   => 500,
            backup => false,
            source => "puppet://${filehost}/files/common/base_centos/etc/rackspace_fw.sh",
            notify => Exec["/etc/init.d/rc.firewall"];
    }

    exec {

        "/etc/init.d/rc.firewall":
            require     => File["/etc/init.d/rc.firewall"],
            subscribe   => File["/etc/init.d/rc.firewall"],
            notify      => Exec["/etc/init.d/iptables save"],
            refreshonly => true;

        "/etc/init.d/iptables save":
            require     => File["/etc/init.d/rc.firewall"],
            subscribe   => File["/etc/init.d/rc.firewall"],
            refreshonly => true;
    }
}
