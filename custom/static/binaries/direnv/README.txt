Ideally I'd use the Direnv installer, however it's rather fucking stupid
in that it downloads the binary and then enumerates the $PATH, finds one
which is writeable and installs the binary there, e.g. it may add it to
~/.cargo/bin or /usr/local/go/bin, etc.