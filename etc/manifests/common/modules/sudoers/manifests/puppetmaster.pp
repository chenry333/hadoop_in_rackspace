class sudoers::puppetmaster {

    include sudoers

    File{
        require => Class["sudoers"],
    }

    file{

        "/etc/sudoers.d/40_puppetmaster.sudo":
            owner    => root,
            group    => root,
            mode     => 400,
            notify   => Exec["rebuild-sudoers.sh"],
            source   => "puppet://${filehost}/files/common/sudoers/puppetmaster.sudo";
    }
}
