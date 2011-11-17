# site.pp

#set our puppet file server host
$filehost = "puppetmaster.example.com"

#load our node, common, and prod pp configs
import "nodes/*.pp"
import "common/*.pp"

# Ignore mercurial repo dirs
File {
    ignore => ".hg",
}
