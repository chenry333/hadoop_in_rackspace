#####
# Sudoers setup Service Module
#####

class sudoers::install {
    
    package{
        "sudo":   ensure => installed;
    }
}


class sudoers::config {

    File{
        require => Class["sudoers::install"],
    }

    file{

        "/etc/sudoers.d":
            ensure   => directory,
            owner    => root,
            group    => root,
            purge    => true,
            mode     => 500;

        "/etc/sudoers.d/00_placeholder.conf":
            owner    => root,
            group    => root,
            mode     => 400,
            notify   => Exec["rebuild-sudoers.sh"],
            content  => "### sudoers header - Managed by Puppet ###\n";

        "/etc/sudoers.d/10_default.sudo":
            owner    => root,
            group    => root,
            mode     => 400,
            notify   => Exec["rebuild-sudoers.sh"],
            source   => "puppet://${filehost}/files/common/sudoers/default.sudo";

    }

    exec{

        "rebuild-sudoers.sh":
            command     => "/bin/mv -f /etc/sudoers.stg /etc/sudoers.stg.bak; /bin/touch /etc/sudoers.stg; chmod 400 /etc/sudoers.stg;/bin/cat /etc/sudoers.d/* >> /etc/sudoers.stg",
            onlyif      => "/usr/bin/test -f /etc/sudoers.d/00_placeholder.conf",
            notify      => Exec["reload-sudoers.sh"],
            refreshonly => true;

        "reload-sudoers.sh":
            command     => "/bin/mv /etc/sudoers /etc/sudoers.bak;/bin/cp /etc/sudoers.stg /etc/sudoers;chmod 440 /etc/sudoers;chown root:root /etc/sudoers",
            onlyif      => "/usr/sbin/visudo -c -f /etc/sudoers.stg",
            refreshonly => true;
    }
}

class sudoers {
    include sudoers::install,
            sudoers::config
}
