### Activate completions system
###
### This needs to happen early on because various scripts which
### append completions to the $fpath or declare completions using
### compdef require the completions system to be loaded.

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle :compinstall filename "$(realpath "$0")"

autoload -Uz compinit
compinit