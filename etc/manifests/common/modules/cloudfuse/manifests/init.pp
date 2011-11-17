class cloudfuse {

    package {
        "upstream-cloudfuse": ensure => installed;
    }

    file {

        "/root/.cloudfuse":
            owner   => root,
            group   => root,
            mode    => 440,
            source  => "puppet://${filehost}/files/common/cloudfuse/cloudfuse_conf";

        "/mnt/cloudfiles":
            ensure  => directory,
            mode    => 775,
            owner   => root,
            group   => root;
    }

    mount {

        "/mnt/cloudfiles":
            ensure   => mounted,
            require  => [Package["upstream-cloudfuse"],File["/mnt/cloudfiles","/root/.cloudfuse"]],
            atboot   => true,
            device   => "cloudfuse",
            options  => "user,rw,noexec,nosuid,nodev,umask=0002,uid=0,gid=0,allow_other",
            fstype   => "fuse";
    }
}
