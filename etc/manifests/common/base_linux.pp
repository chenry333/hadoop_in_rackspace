###
# Include everything common to LINUX
# Note this is _not_ common to each OS
###
class base_linux {

    include ssh
    package {
        "ruby-shadow": ensure => installed;
    }
    
    file {
        "/etc/vimrc":
            owner  => root,
            group  => root,
            mode   => 444,
            source => "puppet://${filehost}/files/common/base_linux/etc/vimrc";

        "/usr/local/sbin/puppet-agent-run.sh":
            owner  => root,
            group  => root,
            mode   => 500,
            source => "puppet://${filehost}/files/common/base_linux/bin/puppet-agent-run.sh";

        "/etc/selinux/config":
            owner  => root,
            group  => root,
            mode   => 444,
            source => "puppet://${filehost}/files/common/base_linux/sysctl/selinux";

        "/etc/cron.d/puppet-agent":
            owner  => root,
            group  => root,
            mode   => 444,
            source => "puppet://${filehost}/files/common/base_linux/etc/puppet-agent-run.cron";

        "/etc/ld.so.conf.d/usrlocallib.conf":
            owner  => root,
            group  => root,
            mode   => 444,
            notify => Exec["ldconfig-update"],
            source => "puppet://${filehost}/files/common/base_linux/etc/usrlocallib.conf";

         #Create a bashrc.d folder for appending to global bashrc files (ext must be .bashrc)
        "/etc/bashrc.d":
            ensure => directory,
            mode   => 755,
            owner  => root,
            group  => root;

        #Create a placeholder to avoid throwning warnings if no files in /etc/bashrc.d
        "/etc/bashrc.d/placeholder.bashrc":
            mode   => 444,
            owner  => root,
            group  => root,
            source => "puppet://${filehost}/files/common/base_linux/etc/placeholder.bashrc";

        "/etc/bashrc":
            mode   => 444,
            owner  => root,
            group  => root,
            source => "puppet://${filehost}/files/common/base_linux/etc/bashrc";

        "/usr/local/bin/rackspace_info.py":
            mode   => 755,
            owner  => root,
            group  => root,
            source => "puppet://${filehost}/files/common/base_linux/bin/rackspace_info.py";
    }

    exec {

        "ldconfig-update":
            command     => "/sbin/ldconfig",
            refreshonly => true;
    }

}
