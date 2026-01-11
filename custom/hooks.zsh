###
### HOOK: Called before any modules are sourced
###
zsh_pre_init() {
    # if [[ -n "$ZSH_EXECUTION_STRING" ]]; then
    #    compdef() { : }
    #    return 0
    # fi

    ###
    ### Activate completions system
    ###
    ### This needs to happen early on because various scripts which
    ### append completions to the $fpath or declare completions using
    ### compdef require the completions system to be loaded.
    ###

    zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
    zstyle :compinstall filename "$PWD"
    setopt local_options extended_glob

    # 1. Cache: stub compdef to queue completion requests until compinit is loaded
    typeset -ga _comp_def_queue
    compdef() { 
      _comp_def_queue+=("$*")
    }

    ###
    ### Execute Tmux
    ###
    ### In the interest of entering tmux in the fast path, we attempt
    ### to extract the binary location, as we haven't yet sourced the
    ### modules which add cargo, brew, etc to the $PATH.
    ###
    if [[ -z "$TMUX" && -e "$HOME/.execute-tmux-on-init" ]]; then
        if [ -e "/opt/homebrew/bin/tmux" ]; then
            start_tmux "/opt/homebrew/bin/tmux"
        elif type tmux &> /dev/null; then
            start_tmux "tmux"
        fi
    fi
}

_load_compinit() {
    unset -f compdef
    autoload -Uz compinit

    # 2. Load: only check for new completions once every 24 hours
    local zwc_file="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ "$zwc_file"(#qN.mh-24) ]]; then
        compinit -C
    else
        compinit
        zcompile "$zwc_file"
    fi

    # 3. Replay: Use the global _comp_def_queue array and load these into the context
    for cmd in "${_comp_def_queue[@]}"; do
        compdef ${(z)cmd}
    done
    unset _comp_def_queue
}

###
### HOOK: Called after modules are sourced
###
zsh_post_init() {
    # Now that modules are loaded, zsh-defer should be available
    if (( $+functions[zsh-defer] )); then
        zsh-defer _load_compinit
    else
        _load_compinit
    fi
}

start_tmux() {
    if [[ $TERM_PROGRAM == "vscode" || $TERMINAL_EMULATOR == "JetBrains-JediTerm" ]]; then
        return 0
    fi

    "$1" new-session -s $(gen_cvcv)

    if [[ -e "$HOME/.kill-session-on-tmux-exit" ]]; then
        exit
    fi
}

gen_cvcv() {
  local vowels=(A E I O U)
  local consonants=(B C D F G H J K L M N P Q R S T V W X Y Z)

  local c1=${consonants[$(( $RANDOM % ${#consonants[@]} ))]}
  local v1=${vowels[$(( $RANDOM % ${#vowels[@]} ))]}
  local c2=${consonants[$(( $RANDOM % ${#consonants[@]} ))]}
  local v2=${vowels[$(( $RANDOM % ${#vowels[@]} ))]}

  echo "${c1}${v1}${c2}${v2}"
}