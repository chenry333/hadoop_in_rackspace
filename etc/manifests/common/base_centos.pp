class base_centos {
    case $operatingsystem {
        CentOS: {
            service{
                "hidd":
                    ensure    => stopped,
                    enable    => false,
                    hasstatus => false;
                "bluetooth":
                    ensure    => stopped,
                    enable    => false,
                    hasstatus => false,
            }
        }
    }

    file {

        "/etc/yum.repos.d/CentOS-Base.repo":
            owner  => root,
            group  => root,
            mode   => 444,
            source => "puppet://${filehost}/files/common/base_centos/etc/CentOS-base.repo";

    }
}
