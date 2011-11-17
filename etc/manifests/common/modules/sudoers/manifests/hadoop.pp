class sudoers::hadoop {

    include sudoers

    File{
        require => Class["sudoers"],
    }

    file{

        "/etc/sudoers.d/30_hadoop.sudo":
            owner    => root,
            group    => root,
            mode     => 400,
            notify   => Exec["rebuild-sudoers.sh"],
            source   => "puppet://${filehost}/files/common/sudoers/hadoop.sudo";
    }
}
