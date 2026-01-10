alias py=python3
alias pip=pip3
alias f=fuck
alias c=clear

# suffix alias
alias -s json="fx"
alias -s md="cat"

# clean
alias hoover="ps -u $(whoami) -o pid,comm | grep -E '/Applications/|/Users/' | grep -vE 'Google Chrome|Ghostty|Terminal' | awk '{print \$1}' | xargs kill -9 2>/dev/null"
alias dry-hoover="ps -u $(whoami) -o pid,comm | grep -E '/Applications/|/Users/' | grep -vE 'Google Chrome|Ghostty|Terminal' | awk '{print \$1}' | xargs ps -p"