#
# Install our CloudServers control requirements
#

class cloudservers::install {

    package {
        "upstream-Python":               ensure  => installed;
        "upstream-ipython":              ensure  => installed;
        "upstream-python-httplib2":      ensure  => installed;
        "upstream-python-cloudservers":  ensure  => installed;
    }
}

class cloudservers {
    include cloudservers::install
}
