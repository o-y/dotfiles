function ds {
    sudo pmset -a sleep 0;
    open /Applications/KeepingYouAwake.app;
}

function sa {
    sudo yabai --load-sa
}

function t {
    # make an assumption. Could check $hostname, but we can assume os x isn't
    # used as a remote-server over ssh env.
    if [[ `uname` == 'Darwin' ]] then
        if ! read -q "choice?FYI: You're running this command on localhost, continue? [y/N] "; then
            echo -e '\r\033[0;32mOK! Exiting...\033[0m\c'
            exit 1;
        fi
    fi

    tmux -CC attach-session -t tmuxssh || tmux -CC new-session -s tmuxssh
}
