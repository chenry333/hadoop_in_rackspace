#####
# This module handles installing of
# java jdk
# 
# by default we install latest jdk
# otherwise we accept specific versions
#####

class jdk($package='jdk') {

## install ##
    package {
        "${package}":
            ensure => present
    }


## config ##
    File {
        owner => root,
        group => root
    }

    file {

        "/var/lib/java":
            ensure => directory,
            mode   => 755;

        "/var/lib/java/dumps":
            ensure => directory,
            mode   => 1777;

        "/usr/bin/java16":
            ensure  => link,
            target  => "/usr/java/latest/jre/bin/java",
            require => Package["${package}"];

        "/etc/bashrc.d/jdk.bashrc":
            mode   => 444,
            group  => root,
            owner  => root,
            source => "puppet://${filehost}/files/common/jdk/etc/jdk.bashrc";
    }       
 
}
