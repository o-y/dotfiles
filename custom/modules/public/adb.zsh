function adbtext() {
  text=$(printf '%s%%s' ${@})  # concatenate and replace spaces with %s
  text=${text%%%s}  # remove the trailing %s
  text=${text//\'/\\\'}  # escape single quotes
  text=${text//\"/\\\"}  # escape double quotes
  echo "writing [$text] to device"

  adb shell input text "$text"
}

function adbtextc {
    text=$(xclip -selection clipboard -o)
    adbtext "$text"
}