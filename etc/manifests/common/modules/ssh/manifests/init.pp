#####
# SSH Service Module
#####

class sshd::server::install {
    
    case $operatingsystem {
        CentOS: {
            package{
                "openssh-server":   ensure => installed;
                "openssh-clients":   ensure => installed;
                "openssh":          ensure => installed;
            }
        }
    }
}


class sshd::server::config {

    File{
        require => Class["sshd::server::install"],
        notify  => Class["sshd::server::service"],
    }

    file{
        "/etc/ssh/sshd_config":
            owner  => root,
            group  => root,
            mode   => 444,
            source => "puppet://${filehost}/files/common/ssh/sshd_config";
    }
}


class sshd::server::service {
    case $operatingsystem {
        CentOS: {
            service{
                "sshd":
                    ensure    => running,
                    enable    => true,
                    require   => Class["sshd::server::config"],
                    hasstatus => true,
                    subscribe => File["/etc/ssh/sshd_config"];
            }
        }
    }
}


class ssh {
    include sshd::server::install,
            sshd::server::config,
            sshd::server::service
}
