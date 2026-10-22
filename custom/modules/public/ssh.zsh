function gtk() {
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/zv
}

ssh() {
  command ssh "$@"
  
  # When SSH exits (whether cleanly, killed, or dropped via timeout),
  # if the host was using tmux, the and this wasn't gracefully exitted,
  # mouse reporting is not disabled, which means clicking on the terminal
  # sends various escape sequences. Therefore this sends the sequences to
  # disable all mouse reporting modes.
  printf "\e[?1000l\e[?1002l\e[?1015l\e[?1006l"
}