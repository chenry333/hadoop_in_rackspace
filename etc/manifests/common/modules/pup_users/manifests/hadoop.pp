##
# This class provides all of the default required users for hadoop
# systems and enables our 'purging' of all non-puppet managed users
# It also imports users with the stock settings from pup_users::all_vusers
class pup_users::hadoop {

    # import all our virtual users
    include pup_users::all_vusers

#    # purge any 'user' resource not managed by puppet
#    # ie: delete users that aren't specifically added via puppet
    resources {
        'user':
            purge => true;
    }

    # add all users in the pup_req, pup_admins, and pop_ops groups
    Pup_users::Pupuser <| groups == pup_req |>
    Pup_users::Pupuser <| groups == pup_admins |>
    Pup_users::Pupuser <| groups == hadoop |>

}
