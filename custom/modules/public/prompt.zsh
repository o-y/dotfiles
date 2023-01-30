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

export PROMPT='%B${COLOR_USR}%n${COLOR_AT}@${COLOR_USR}%m ${COLOR_DIR}%~ ${COLOR_GIT}$(parse_git_branch)${COLOR_DEF}${NEWLINE}~%b '