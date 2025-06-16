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

###
### HOOK: Called after modules are sourced
###
zsh_post_init() {
    
}

start_tmux() {
    # Don't auto-start inside VS Code's integrated terminal
    if [[ $TERM_PROGRAM == "vscode" ]]; then
        return 0
    fi

    "$1" new-session -s $(gen_cvcv)

    if [[ -e "$HOME/.kill-session-on-tmux-exit" ]]; then
        
    fi
}

gen_cvcv() {
  local vowels=(A E I O U)
  local consonants=(B C D F G H J K L M N P Q R S T V W X Y Z)

  # This now works because zmodload makes $RANDOM dynamic
  # NOTE: This assumes 0-indexed arrays, which Zsh uses inside functions
  # for compatibility (KSH_ARRAYS option is on by default).
  local c1=${consonants[$(( $RANDOM % ${#consonants[@]} ))]}
  local v1=${vowels[$(( $RANDOM % ${#vowels[@]} ))]}
  local c2=${consonants[$(( $RANDOM % ${#consonants[@]} ))]}
  local v2=${vowels[$(( $RANDOM % ${#vowels[@]} ))]}

  echo "${c1}${v1}${c2}${v2}"
}