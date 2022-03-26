function dsleep {
    sudo pmset -a sleep 0;
    open /Applications/KeepingYouAwake.app;
}

function sa {
    sudo yabai --load-sa
}

function t {
    if [[ `uname` == 'Darwin' ]]
    then
        read -r -p "FYI: You're running this command from your Macbook, continue? [enter] to continue" response
    fi

    tmux -CC attach-session -t tmuxssh || tmux -CC new-session -s tmuxssh
}
