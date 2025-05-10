alias py=python3
alias pip=pip3
alias f=fuck
alias c=clear

# This is a workaround for the `clear` command being
#  overrided in some environments (e.g. Pixi, etc.)
function clear() {
    if [[ -e /usr/bin/clear ]]; then
        /usr/bin/clear
        return
    fi
    if [[ -e /bin/clear ]]; then
        /bin/clear
        return
    fi
    clear
}