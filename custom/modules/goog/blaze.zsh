function wrapped_blaze() {
  local exit_code
  local target

  target="${!#}"
  blaze "$@"
  exit_code=$?

  if [ $exit_code -eq 0 ]; then
    notify-send "Bazel succeeded!"
  else
    notify-send "Bazel failed!"
  fi

  return $exit_code
}

#### Blaze alias
alias blaze=wrapped_blaze
alias blaze2='blaze --output_base=/tmp/blaze-out-2'
alias blaze3='blaze --output_base=/tmp/blaze-out-3'
alias blaze4='blaze --output_base=/tmp/blaze-out-4'
alias blaze5='blaze --output_base=/tmp/blaze-out-5'
alias blaze6='blaze --output_base=/tmp/blaze-out-6'
alias blaze7='blaze --output_base=/tmp/blaze-out-7'
alias blaze8='blaze --output_base=/tmp/blaze-out-8'
alias blaze9='blaze --output_base=/tmp/blaze-out-9'