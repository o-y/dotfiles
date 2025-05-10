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
    ### to extract the binary location, as we haven't yet sourced the
    ### modules which add cargo, brew, etc to the $PATH.
    ###
    if [[ -z "$ZELLIJ" && -e "$HOME/.execute-zellij-on-init" ]]; then
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
    exec "$1"

    if [ -e "$HOME/.exit-zellij-on-session-terminate" ]; then
        exit
    fi
}