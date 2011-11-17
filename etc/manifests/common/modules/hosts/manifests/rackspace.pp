#
## include our infra server in the hosts file
#

class hosts::rackspace {

    include hosts

    file {

        "/etc/hosts.d/30_rackspace.hosts":
            mode   => 400,
            owner  => root,
            group  => root,
            notify => Exec["rebuild-hosts.sh"],
            source => "puppet://${filehost}/files/common/hosts/rackspace.hosts";

    }

}
