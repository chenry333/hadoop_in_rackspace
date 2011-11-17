#####
# Puppetmaster Service Module
#####

class puppetmaster::server::gems {

    Package {
        require => Package["rubygems","upstream-httpd","make"],
        provider => gem,
        source   => "http://yum.smwa.net/upstream/centos_5_5_64/x86_64/other",
    }

    package {
        # Install our ruby gems required for puppetmaster/passenger
        "fastthread":
            ensure => installed;
        "rake":
            ensure => installed;
        "rack":
            ensure => installed;
        "passenger":
            ensure => installed,
            notify => Exec["compile_passenger_mod"];
    }
}

class puppetmaster::server::install {

    package {
        "make":                          ensure  => installed;
        "gcc-c++":                       ensure  => installed;
        "rubygems":                      ensure  => installed,
                                         require => Package["gcc-c++","ruby-devel","ruby-rdoc"];
        "mercurial":                     ensure  => installed;
        "ruby-rdoc":                     ensure  => installed;
        "ruby-devel":                    ensure  => installed;
        "puppet-server":                 ensure  => installed;
        "upstream-python-cloudfiles":    ensure  => installed;
    }

    File {
        owner   => root,
        group   => root,
        mode    => 750
          
    }


    file {

        "/puppet":
            ensure => directory,
            mode   => 755;

        "/puppet/files":
            ensure => link,
            mode   => 755,
            target => "/var/lib/puppet/files";

        #push out our rackspace scripts
        "/usr/local/bin/rackspace_refresh.py":
            source => "puppet://${filehost}/files/common/puppetmaster/bin/rackspace_refresh.py";

        "/usr/local/bin/rackspace_refresh_hadoop.py":
            source => "puppet://${filehost}/files/common/puppetmaster/bin/rackspace_refresh_hadoop.py";

        "/usr/local/bin/rackspace_provision.py":
            source => "puppet://${filehost}/files/common/puppetmaster/bin/rackspace_provision.py";

        "/usr/local/apache2/conf/proxy-htpasswd":
            mode   => 444,
            source => "puppet://${filehost}/files/common/puppetmaster/conf/proxy-htpasswd";
    }

    cron {
        "rackspace_updates":
            command => "/usr/local/bin/rackspace_refresh_hadoop.py c1",
            user    => root,
            minute  => "*/15";
    }

    exec {

        # Compile the passenger apache module after passenger gem is installed
        "compile_passenger_mod":
            command     =>"/usr/bin/passenger-install-apache2-module --apxs-path=/usr/local/apache2/bin/apxs -a",
            subscribe   => Package["passenger"],
            require     => Package["passenger"],
            creates     => "/usr/lib64/ruby/gems/1.8/gems/passenger-2.2.11/ext/apache2/mod_passenger.so",
            user        => root,
            refreshonly => true;
    }
}


class puppetmaster::server::config {

    case $operatingsystem {
        CentOS: {
            File{
                require => Class["puppetmaster::server::install"],
                owner   => root,
                group   => root,
                mode    => 444
            }

            file{

                "/usr/local/apache2/conf.d/aa_httpd_enable_NameVirtual.conf":
                    require => Class["puppetmaster::server::install"],
                    notify  => Service["apachectl"],
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/aa_httpd_enable_NameVirtual.conf";
    
                "/usr/local/apache2/conf.d/puppet.conf":
                    require => Class["puppetmaster::server::install"],
                    notify  => Service["apachectl"],
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/puppet_apache.conf";

                "/usr/local/apache2/conf.d/hadoop-proxy-c1.conf":
                    require => Class["puppetmaster::server::install"],
                    notify  => Service["apachectl"],
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/hadoop-proxy-c1.conf";

                "/usr/local/apache2/conf.d/hadoop-proxy-c2.conf":
                    require => Class["puppetmaster::server::install"],
                    notify  => Service["apachectl"],
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/hadoop-proxy-c2.conf";

                "/usr/local/apache2/conf.d/apache-mpm.conf":
                    require => Class["puppetmaster::server::install"],
                    notify  => Service["apachectl"],
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/apache-mpm.conf";

                "/etc/puppet/puppet.conf":
                    require => Class["puppetmaster::server::install"],
                    owner   => puppet,
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/etc/puppet.conf";

                "/etc/puppet/fileserver.conf":
                    require => Class["puppetmaster::server::install"],
                    owner   => puppet,
                    source  => "puppet://${filehost}/files/common/puppetmaster/conf/etc/fileserver.conf";

                "/etc/puppet/rack":
                    ensure => directory,
                    owner  => puppet,
                    group  => puppet,
                    mode   => 755;

                "/etc/puppet/rack/public":
                    ensure => directory,
                    owner  => puppet,
                    group  => puppet,
                    mode   => 755;

                "/etc/puppet/rack/config.ru":
                    owner  => puppet,
                    group  => puppet,
                    source => "puppet://${filehost}/files/common/puppetmaster/conf/config.ru";

                "/var/lib/puppet/files":
                    ensure  => directory,
                    owner   => puppet,
                    group   => puppet,
                    mode    => 755;
            }                    
        }
    }
}

class puppetmaster {
    include puppetmaster::server::install,
            puppetmaster::server::config,
            puppetmaster::server::gems
}
