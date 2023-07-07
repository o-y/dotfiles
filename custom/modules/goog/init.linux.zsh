# it would be worth considering a more maintable way of handling files scoped to specific hostnames
if [[ $(hostname) == "slyo.lon.corp.google.com" ]]; then
    source /etc/bash_completion.d/hgd 2> /dev/null
    source /etc/bash_completion.d/g4d 2> /dev/null

    if [ -d /google/data ]; then
        fpath=(/google/src/files/head/depot/google3/devtools/blaze/scripts/zsh_completion $fpath)
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zsh/cache
    fi
fi