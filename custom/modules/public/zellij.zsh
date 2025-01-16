# zellij alias
alias ze=zellij

# zellij run [command]
function zr() { 
    zellij run --name "$*" -- zsh -ic "$*"
}

# zellij edit file [file]
function hxz() {
    zellij edit "$@"
}