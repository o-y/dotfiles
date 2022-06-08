#### Fix for "requires authenticator" error - not sure how useful this is, so commented out to profile.
autoload -Uz add-zsh-hook
function refresh_file_handle() {
  cd .
}
add-zsh-hook preexec refresh_file_handle

#### Removes a specific file from any CL and banishes it to the default changelist
#### usage: remvcl <file path>, e.g remvcl java/com/google/android/libraries/web/BUILD
function remvcl() {
  g4 reopen -c default $1
}
