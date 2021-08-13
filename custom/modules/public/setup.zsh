# declare -A profileMappedToBackgrounds=( 
#     [1]=~/.cli/artwork/bg1.jpg
#     [2]=~/.cli/artwork/bg2.jpg
#     [3]=~/.cli/artwork/bg3.jpg
#     [4]=~/.cli/artwork/bg4.jpg
#     [5]=~/.cli/artwork/bg5.jpg
# )
# 
# Neofetch is disabled at the moment
# randInt=$(($RANDOM % 5 + 1))
# neofetch --source $profileMappedToBackgrounds[$randInt]

PATH_TO_SCRIPT=`realpath -s "$0"`
PATH_TO_SCRIPT_DIR=`dirname "$PATH_TO_SCRIPT"`
LIB="$PATH_TO_SCRIPT_DIR/../../lib"

if [ $TERM_PROGRAM = "iTerm.app" ]
then 
    source "$LIB/iterm/iterm2_shell_integration.zsh"
fi

source "$LIB/pokemon/init.sh"