function dsleep {
    sudo pmset -a sleep 0;
    open /Applications/KeepingYouAwake.app;
}

function sa {
    sudo yabai --install-sa
}

function proxy_adb {
    ssh -L 5037:localhost:5037 slyo1.lon.corp.google.com
}

function rproxy_adb {
    ssh -R 5037:localhost:5037 slyo1.lon.corp.google.com
}

function tmux_con {
    ssh slyo1.lon.corp.google.com
}
