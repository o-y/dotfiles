function esleep() {
  echo "enabling sleep"
  sudo pmset -b sleep 0; sudo pmset -b disablesleep 0
}

function dsleep() {
  echo "disabling sleep"
  sudo pmset -b sleep 1; sudo pmset -b disablesleep 1
}
