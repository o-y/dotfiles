function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}

COLOR_USR=$'\e[38;5;255m'
COLOR_AT=$'\e[38;5;250m'
COLOR_DIR=$'\e[38;5;38m'
COLOR_GIT=$'\e[38;5;219m'

NEWLINE=$'\n'
COLOR_DEF=$'\e[38;5;250m'

setopt PROMPT_SUBST

PROMPT='%B'                                # start of bold sequence
PROMPT+="${COLOR_USR}%n"                   # display username
PROMPT+="${COLOR_AT}@"                     # display @ symbol
PROMPT+="${COLOR_USR}%m"                   # display hostname
PROMPT+=" ${COLOR_DIR}%~"                  # display current directory
PROMPT+=" ${COLOR_GIT}$(parse_git_branch)" # display git branch
PROMPT+="${COLOR_DEF}${NEWLINE}"           # reset colour and add newline
PROMPT+='~%b '                             # display tilde

export PROMPT