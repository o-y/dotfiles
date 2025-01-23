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

# updating tab
zellij_tab_name_update() {
    if [[ -n $ZELLIJ ]]; then
        local current_dir=$PWD
        if [[ $current_dir == $HOME ]]; then
            current_dir="~"
        else
            current_dir=${current_dir##*/}
        fi

        command nohup zellij action rename-tab $current_dir >/dev/null 2>&1
    fi
}

# zellij_session_name_update() {
#     if [[ -n $ZELLIJ ]]; then
#         command nohup  zellij action rename-session "$(openssl rand -base64 10 | tr -dc 'A-Za-z0-9' | head -c 5)" >/dev/null 2>&1
#     fi
# }
# zellij_session_name_update

zellij_tab_name_update
chpwd_functions+=(zellij_tab_name_update)