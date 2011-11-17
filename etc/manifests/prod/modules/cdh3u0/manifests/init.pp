#
# Our CDH3 class
#

class cdh3u0::common {

    class {
        "jdk":
            package => "jdk-1.6.0_24"
    }

    package {
        "hadoop-0.20": ensure => installed;
        "upstream-hadoop-lzo": ensure => latest;
    }

    File {
        require => Package["hadoop-0.20"],
        owner   => root,
        group   => root,
        mode    => 755

    }

    file {

        
        "/hadoop":
            ensure => directory;

        "/hadoop/mapred":
            ensure => directory,
            owner  => mapred,
            group  => mapred;

        "/hadoop/mapred/tmp":
            ensure => directory,
            owner  => mapred,
            group  => mapred;
        
        "/hadoop/hdfs":
            ensure => directory,
            owner  => hdfs,
            group  => hdfs;

        "/var/lib/hadoop":
            ensure => directory;

        "/usr/lib/hadoop/bin/hadoop":
            content => template('cdh3u0/hadoop_bin.erb');
    
        "/usr/lib/hadoop/conf/rack.conf":
            mode   => 444,
            content => template('cdh3u0/hadoop_rack_conf.erb');
    
        "/usr/lib/hadoop/conf/masters":
            mode   => 444,
            content => template('cdh3u0/hadoop_masters.erb');
    
        "/usr/lib/hadoop/conf/slaves":
            mode   => 444,
            content => template('cdh3u0/hadoop_slaves.erb');
    
        "/usr/lib/hadoop/conf/core-site.xml":
            mode   => 444,
            content => template('cdh3u0/hadoop_core_site.erb');
    
        "/usr/lib/hadoop/conf/hdfs-site.xml":
            mode   => 444,
            content => template('cdh3u0/hadoop_hdfs_site.erb');

        "/usr/lib/hadoop/conf/mapred-site.xml":
            mode   => 444,
            content => template('cdh3u0/hadoop_mapred_site.erb');
    
        "/usr/lib/hadoop/conf/log4j.properties":
            mode   => 444,
            content => template('cdh3u0/hadoop_log4j.erb');
    
        "/var/run/hadoop":
            ensure => directory;
    
        "/usr/lib/hadoop/logs":
            ensure => directory,
            mode   => 777;
    
        "/usr/lib/hadoop/pids":
            ensure => link,
            force  => true,
            target => "/var/run/hadoop-0.20";
    
        "/etc/bashrc.d/hadoop.bashrc":
            mode   => 444,
            source => "puppet://${filehost}/files/prod/cdh3u0/conf/hadoop.bashrc";
    
        "/usr/lib/hadoop/bin/rack.sh":
            mode   => 555,
            content => template('cdh3u0/hadoop_rack_bin.erb');
    
    }

}


class cdh3u0::slaves {

    package {
        "hadoop-0.20-datanode":    ensure => installed;
        "hadoop-0.20-tasktracker": ensure => installed;
    }


    File {
        require => Package["hadoop-0.20-datanode","hadoop-0.20-tasktracker"]
    }

    file {

        "/hadoop/hdfs/datanode":
            ensure => directory,
            owner  => hdfs,
            group  => hdfs,
            mode   => 755
    }

    service {
        "hadoop-0.20-datanode":
            ensure    => running,
            enable    => true,
            require   => [ Package["hadoop-0.20-datanode","hadoop-0.20-tasktracker","upstream-hadoop-lzo"],
                           File["/usr/lib/hadoop/conf/hdfs-site.xml","/usr/lib/hadoop/conf/core-site.xml"],
                           Exec["rebuild-hosts.sh"]],
            hasstatus => true;

        "hadoop-0.20-tasktracker":
            ensure    => running,
            enable    => true,
            require   => [ Package["hadoop-0.20-datanode","hadoop-0.20-tasktracker","upstream-hadoop-lzo"],
                           File["/usr/lib/hadoop/conf/mapred-site.xml","/usr/lib/hadoop/conf/core-site.xml"]],
            hasstatus => true;

    }
}
class cdh3u0::jobtracker {
    
    package {
        "hadoop-0.20-jobtracker":   ensure => installed;
    }

    service {
        "hadoop-0.20-jobtracker":
            ensure    => running,
            enable    => true,
            hasstatus => true,
            require  => [ Exec["namenode_tmp"],
                          Service["hadoop-0.20-namenode"],
                          Package["hadoop-0.20-jobtracker","upstream-hadoop-lzo"],
                          File["/usr/lib/hadoop/conf/mapred-site.xml","/usr/lib/hadoop/conf/core-site.xml","/usr/lib/hadoop/bin/hadoop"]];
    }


}

class cdh3u0::namenode {

    package {
    
        "hadoop-0.20-namenode":
            ensure => installed,
            notify => Exec["namenode_format"];
        "screen":
            ensure => installed;

    }

    file {

        "/hadoop/hdfs/name-node":
            ensure => directory,
            owner  => hdfs,
            group  => hdfs,
            mode   => 755;

        "/hadoop/hdfs/name-node/name-node-stock.tar.gz":
            owner  => hdfs,
            group  => hdfs,
            mode   => 755,
            source => "puppet://${filehost}/files/prod/cdh3u0/conf/name-node-stock.tar.gz";

        "/hadoop/hdfs/s-name-node":
            ensure => directory,
            owner  => hdfs,
            group  => hdfs,
            mode   => 755;

    }

    exec {

        "namenode_format":
            command     => "/bin/tar -zxsf /hadoop/hdfs/name-node/name-node-stock.tar.gz -C /hadoop/hdfs/",
            require     => [Package["hadoop-0.20-namenode"],File["/hadoop/hdfs/name-node/name-node-stock.tar.gz"]],
            onlyif      => "/usr/bin/test ! -d /hadoop/hdfs/name-node/current/",
            before      => Service["hadoop-0.20-namenode"],
            notify      => Exec["namenode_tmp"],
            refreshonly => true;

        "namenode_tmp":
            command     => "/bin/sleep 10;/usr/bin/hadoop dfs -mkdir /tmp;/usr/bin/hadoop dfs -chmod 777 /tmp;/usr/bin/hadoop dfs -mkdir /mapred;/usr/bin/hadoop dfs -chown mapred /mapred",
            user        => hdfs,
            require     => Service["hadoop-0.20-namenode"],
            refreshonly => true;


    }

    service {
        "hadoop-0.20-namenode":
            ensure    => running,
            enable    => true,
            before    => Exec["namenode_tmp"],
            hasstatus => true,
            require   => [ Package["hadoop-0.20-namenode"],
                           File["/usr/lib/hadoop/conf/hdfs-site.xml","/usr/lib/hadoop/conf/core-site.xml","/usr/lib/hadoop/bin/hadoop"],
                           Exec["rebuild-hosts.sh"]];

    }

}


class cdh3u0 {

    include cdh3u0::common

    if $hostname =~ /^c[0-9]-n[0-9]{3}$/ {
        include cdh3u0::slaves
    }
    if $hostname =~ /^c[0-9]-m001$/ {
        include cdh3u0::jobtracker
    }
    if $hostname =~ /^c[0-9]-m001$/ {
        include cdh3u0::namenode
    }

}
