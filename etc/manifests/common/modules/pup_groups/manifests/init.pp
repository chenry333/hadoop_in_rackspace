#
# Creates virtual group resource
# that can be realized in any module that employs it
#
# Requires:
#   $gid
    
# Optional:
#   $ensure   (defaults to "present")
class pup_groups {
    
    define pupgroup($gid, $ensure = "present" ) {

        # create group

        # create primary group
        if ! defined ( Group[$name]) {
            group { 
                "$name":
                    gid      => "$gid",
                    ensure   => "$ensure",
            } # end group
        } # end if
    } # pupgroup
} # pup_groups class
