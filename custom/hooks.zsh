###
### HOOK: Called before any modules are sourced
###
zsh_pre_init() {
    ###
    ### Activate completions system
    ###
    ### This needs to happen early on because various scripts which
    ### append completions to the $fpath or declare completions using
    ### compdef require the completions system to be loaded.
    ###

    zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
    zstyle :compinstall filename "$(realpath ./)"

    autoload -Uz compinit
    compinit

    ###
    ### Execute Zellij
    ### 
    ### In the interest of entering zellij in the fast path, we attempt
    ### to determine if zellij is installed via heuristics and fallbacks
    ###
    if [[ -z "$ZELLIJ" ]]; then
        if [ -e "$HOME/.cargo/bin/zellij" ]; then
            start_zellij "$HOME/.cargo/bin/zellij"
        elif type zellij &> /dev/null; then
            start_zellij "zellij"
        elif [ -e "/opt/homebrew/bin/zellij" ]; then
            start_zellij "/opt/homebrew/bin/zellij"
        fi
    fi
}

###
### HOOK: Called after modules are sourced
###
zsh_post_init() {

}

start_zellij() {
    if [[ -z "$ZELLIJ" ]]; then
        if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
            "$1" attach -c
        else
            "$1"
        fi

        if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
            exit
        fi
    fi
}