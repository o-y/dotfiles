function dsleep {
    sudo pmset -a sleep 0;
    open /Applications/KeepingYouAwake.app;
}

function sa {
    sudo yabai --install-sa
}

function t {
    tmux -CC attach-session -t tmuxssh || tmux -CC new-session -s tmuxssh
}
