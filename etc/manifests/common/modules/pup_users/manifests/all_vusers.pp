#
#
# This contains _all_ of our puppet managed user definitions
# These are all virtual resources so they have to be realized
# to be applied to a server
#
# Resource pupuser
# Requires:
#   $uid

# Optional:
#   $gid          Primary GID - (defaults to $uid)
#   $group        Primary Group Name - (defaults to $name.  Group name of the user
#   $groups       Groups user belongs in - (defaults to undefined.  Multiple groups need to be passed as an array)
#   $shell        Default Shell - (defaults to /bin/nologin)
#   $home         User Home Directory - (defaults to /home/username)
#   $ensure       Puppet Ensure Value For User Account - (defaults to "present")
#   $password     Users Password/Shadow Hash - (defaults to NO password - ie: !!)
#   $comment      Users Gecos/Comment Field.  Preferred: "fname lname" - (defaults to "created via Puppet")
#   $mode         Home Directory Octal Permissions - (defaults to 0700)
#   $sshdir       Puppet Ensure Value for Users .ssh folder - (defaults to present)
#   $sshkey_users Array of users whose  public ssh key should be added to the authorized_keys - (defaults to undef)

#   $priv_sshkey  Puppet File Server Path to Users private ssh key - (defaults to undef)

 
class pup_users::all_vusers inherits pup_users {
 

    @pupuser {

        "root":
            uid          => "0",
            password     => '!!', # You may want to change this to the hash of a password you want
            comment      => "root",
            home         => "/root",
            groups       => ["pup_all","pup_req","sys","wheel","disk","bin","daemon","adm"],
            sshkey_users => ["chrish"],
            shell        => "/bin/bash";

        "hdfs":  
            uid          => "101",
            gid          => "103",
            password     => '!!',
            comment      => "HDFS User",
            groups       => ["pup_all","hadoop"],
            sshkey_users => ["chrish","bmason"],
            shell        => "/bin/bash";

        "mapred":  
            uid          => "100",
            gid          => "104",
            password     => '!!',
            comment      => "Mapred User",
            groups       => ["pup_all","hadoop"],
            sshkey_users => ["chrish","bmason"],
            shell        => "/bin/bash";

        "puppet":
            uid          => "1023",
            password     => "!!",
            comment      => "Puppet",
            groups       => ["pup_all","pup_req"],
            sshkey_users => ["puppet"],
            home         => "/var/lib/puppet",
            shell        => "/bin/bash";

        "chrish":
            uid          => "9001",
            comment      => "Chris Henry",
            gid          => "9998",
            group        => "common",
            groups       => ["pup_all","pup_admins"],
            sshkey_users => ["chrish"],
            shell        => "/bin/bash";

    } # end file
} # end pup_users::all_vusers
