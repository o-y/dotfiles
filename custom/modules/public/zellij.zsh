# zellij alias
alias ze=zellij

# zellij attach [container]
function za() {
    zellij attach "$*"
}

# zellij run [command]
function zr() { 
    zellij run --name "$*" -- zsh -ic "$*"
}

# zellij run floating [command]
function zrf() { 
    zellij run --name "$*" --floating -- zsh -ic "$*"
}

# zellij edit file [file]
function zed() {
    zellij edit "$@"
}

function zs() {
    sessions=$(zellij list-sessions --no-formatting | awk '{print $1, $3}')
    selected_session=$(echo "$sessions" | fzf --height ${FZF_TMUX_HEIGHT:-20%})
    za $selected_session | awk '{print $1}'
}