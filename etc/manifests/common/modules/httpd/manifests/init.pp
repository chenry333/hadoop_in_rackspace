#####
# httpd Service Module
#####

class httpd {
    
    case $operatingsystem {
        CentOS: {
            package{
                "upstream-httpd": ensure  => installed;
                "elinks":         ensure  => installed;
            }
        }
    }

    group {

        "apache":
            gid     => 48,
            ensure  => present;
            
    }

    user {

        "apache":
            uid        => 48,
            gid        => 48,
            home       => "/usr/local/apache2",
            shell      => "/sbin/nologin",
            ensure     => present,
            comment    => "Apache User",
            require    => Group["apache"],
            managehome => false;
    }


    service {

        "apachectl":
            ensure    => running,
            enable    => true,
            require   => Package["upstream-httpd"],
            hasstatus => true,
            restart   => "/etc/init.d/apachectl graceful";
    }
}
