#
#
# Creates a user/group that can be realized in any module that employs it

# Class Requires: Class["pup_groups::all_vgroups"]

# 
# Resource pupuser:

# Requires:
#   $uid
    
# Optional:
#   $gid          Primary GID - (defaults to $uid)
#   $group        Primary Group Name - (defaults to $name.  Group name of the user
#   $groups       Groups user belongs in - (defaults to undefined.  groups need to be passed in as an array)
#   $user_groups  Other User default groups user belongs in - (defaults to undefined. Groups need to be passed in as an array)
#   $shell        Default Shell - (defaults to /bin/nologin)
#   $home         User Home Directory - (defaults to /dev/null)
#   $ensure       Puppet Ensure Value For User Account - (defaults to "present")
#   $password     Users Password/Shadow Hash - (defaults to NO password - ie: *)
#   $comment      Users Gecos/Comment Field.  Preferred: "fname lname" - (defaults to "created via Puppet")
#   $mode         Home Directory Octal Permissions - (defaults to 0700)
#   $sshdir       Puppet Ensure Value for Users .ssh folder - (defaults to present)
#   $sshkey_users Array of users whose  public ssh key should be added to the authorized_keys - (defaults to undef)
#   $priv_sshkey  Puppet File Server Path to Users private ssh key - (defaults to undef)
    
class pup_users {
    include pup_groups::all_vgroups

    Group {
        allowdupe => true
    }

    define pupuser($uid, $gid = undef, $group = undef, $groups = undef, $user_groups = undef, $shell = "/sbin/nologin", $home = undef, $ensure = "present", $password="*", $comment = "created via Puppet", $mode = undef, $sshdir = "ensure", $sshkey_users = undef, $priv_sshkey = undef ) {

    #### Setup our users ####
        # if $gid isn't specified - set to $uid
        if $gid {
            $mygid = $gid
        } else {
            $mygid = $uid
        }
    
        # if group is unspecified, use the username
        if $group {
            $mygroup = $group
        } else {
            $mygroup = $name
        }
    
        # if home is unspecified, use /home/$name
        if $home {
            $myhome = $home
        } else {
            $myhome = "/home/$name"
        }
    
        # if mode is unspecified, use 0700
        if $mode {
            $mymode = $mode
        } else {
            $mymode = "700"
        }

        # pull groups from pup_groups and user_groups.  
        # Any pup_group specified in the groups array will be virtualized there
        if $groups {
            realize(Pup_groups::Pupgroup[$groups])
            if $user_groups {
                ### combining arrays didn't work well - so we used an inline template ###
                $mygroups = split(inline_template("<%= (groups+user_groups).join(',') %>"),',')
            } else {
                $mygroups = $groups
            }
        } elsif $user_groups {
            $mygroups = $user_groups
        } else {
            $mygroups = undef
        }
 
        # create user
        user { 
            "$name":
                uid        => "$uid",
                gid        => "$mygid",
                shell      => "$shell",
                groups     => $mygroups,
                membership => inclusive,
                home       => "$myhome",
                ensure     => "$ensure",
                password   => "$password",
                comment    => "$comment",
                require    => Group["$mygroup"],
        } # end user
        
        # create primary group
        if ! defined ( Group[$mygroup]) {
            group {
                "$mygroup":
                    gid    => "$mygid",
                    name   => "$mygroup",
                    ensure => "$ensure",
            } # end group
        } # enf if
    
        # create home dir files
        file {
            "$myhome":
                ensure  => $ensure ? {
                    absent => absent,
                    present => directory,
                },
                mode    => $mymode,
                owner   => "$name",
                group   => "$mygroup",
                require => User["$name"];

            "${myhome}/.bash_profile":
                ensure  => $ensure ? {
                    absent => absent,
                    present => file,
                },
                mode    => 644,
                owner   => "$name",
                group   => "$mygroup",
                require => User["$name"],
                source  => "puppet://${filehost}/files/common/pup_users/conf/bash_profile";

        } # file
   
    ### if we have sshdir required then make it and check for
    ### public and private key definitions 
        case $sshdir {
            "ensure","true": {
                file {
                    "${myhome}/.ssh":
                        ensure  => directory,
                        mode    => "700",
                        owner   => "$name",
                        group   => "$mygroup",
                        require => User["$name"],
                } # end file
            
                ### if we have an sshdir and an sshkey_users defined - drop in their ssh key ###
                if $sshkey_users {
                    file {
                        "${myhome}/.ssh/authorized_keys":
                            mode     => "444",
                            owner    => "$name",
                            group    => "$mygroup",
                            require  => File["${myhome}/.ssh"],
                            content  => template("pup_users/sshkey_users.erb");
                    } # end file 
                } # end if

                #### if we have an sshdir and a priv_sshkey defined - drop in their ssh key ###
                if $priv_sshkey {
                    file {
                        "${myhome}/.ssh/id_dsa":
                            mode    => "400",
                            owner   => "$name",
                            group   => "$mygroup",
                            require => File["${myhome}/.ssh"],
                            source  => ["puppet://${filehost}/files/${priv_sshkey}",
                                        "puppet://${filehost}/files/common/pup_users/ssh_keys/${name}/${name}.priv"];
                    } #end file
                } # end if

            } # end "ensure" "true"
        } # end case
    } # end pupuser
} # end pup_users class
