if [[ $(hostname) == *corp.google.com || $(hostname) == *c.googlers.com ]]; then
    source /etc/bash_completion.d/hgd 2> /dev/null
    source /etc/bash_completion.d/g4d 2> /dev/null
    source /etc/bash_completion.d/jjd 2> /dev/null

    if [ -d /google/data ]; then
        fpath=(/google/src/files/head/depot/google3/devtools/blaze/scripts/zsh_completion $fpath)
    fi
fi