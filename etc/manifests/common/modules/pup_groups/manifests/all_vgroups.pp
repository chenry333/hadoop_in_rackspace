#
#
# This contains of our puppet managed group definitions
# except for specific 'user' groups which are in the pup_users module.
# These are all virtual resources so they have to be realized
# to be applied to a server

class pup_groups::all_vgroups inherits pup_groups {

    @pupgroup {

        "bin":
            gid  => "1";

        "daemon":
            gid  => "2";

        "sys":
            gid  => "3";

        "adm":
            gid  => "4";

        "disk":
            gid  => "6";

        "wheel":
            gid  => "10";

        "hadoop":
            gid  => "102";

        "common":
            gid  => "9998";

        "sftponly":
            gid  => "9999";

        "pup_all":
            gid  => "10001";

        "pup_req":
            gid  => "10002";

        "pup_admins":
            gid  => "10003";

    } # end pupgroup
} # end pup_groups::all_vgroups
