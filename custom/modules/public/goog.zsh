#### Fix for "requires authenticator" error
autoload -Uz add-zsh-hook
function refresh_file_handle() {
  cd .
}
add-zsh-hook preexec refresh_file_handle
