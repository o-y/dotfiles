
# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle :compinstall filename '/Users/zv/dotfiles/comp.zsh'

autoload -Uz compinit
compinit
# End of lines added by compinstall
