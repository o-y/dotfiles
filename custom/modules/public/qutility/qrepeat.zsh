##
## qrepeat - Command Repeater
##
qrepeat() {
    local usage() {
        echo "qrepeat - Command Repeater"
        echo "Usage: qrepeat <interval> <command>"
        echo "  interval    time between each command [e.g 5s, 2m, 1h, 3d]"
        echo "  command     the command which should be executed" 
    }

    local time_to_seconds() {
        local time_notation=$1
        local num=${time_notation%[a-zA-Z]*}
        local unit=${time_notation//[0-9.]}

        if ! [[ $num =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            echo "[qrepeat] invalid time notation: $time_notation"
            usage
            return 1
        fi

        case $unit in
            "s") echo "$num";;
            "m") echo "$((num * 60))";;
            "h") echo "$((num * 3600))";;
            "d") echo "$((num * 86400))";;
            *) echo "[qrepeat] invalid time notation: $time_notation"
            usage
            return 1;;
        esac
    }

    if [[ $# -lt 2 ]]; then
        usage
        return 1
    fi

    local interval=$(time_to_seconds $1)
    shift
    local command=$@

    echo "[qrepeat]: executing every $interval second(s): $command"
    while true; do
        eval $command
        sleep $interval
    done
}

##
## qrepeat - Zsh Completion Engine
##
_qrepeat() {
    if (( CURRENT == 2 )); then
        _message -e intervals 'interval (e.g. 5s, 2m, 1h, 3d)'
        return
    fi

    shift 2 words
    (( CURRENT -= 2 ))

    _normal
}
compdef _qrepeat qrepeat

##
## qrepeat live hints
##
# _qrepeat_live_hints() {
#     if [[ "$BUFFER" == qrepeat\ * ]]; then
#         _QREPEAT_HINT_ACTIVE=1
#         local -a current_words
#         current_words=(${(z)BUFFER})
        
#         local word_count=${#current_words[@]}
#         [[ "$BUFFER" =~ " $" ]] && ((word_count++))

#         local hint=""
#         case $word_count in
#             2) 
#                 hint="󰁔 <interval> (e.g. 5s, 2m, 1h, 3d)" 
#                 ;;
#             *) 
#                 hint="󰁔 <command> (to execute every ${current_words[2]})"
#                 ;;
#         esac

#         if [[ -n "$hint" ]]; then
#             zle -M "$hint"
#         else
#             zle -M ""
#         fi
#     elif (( _QREPEAT_HINT_ACTIVE == 1 )); then
#         _QREPEAT_HINT_ACTIVE=0
#         zle -M ""
#     fi
# }

# autoload -Uz add-zle-hook-widget
# add-zle-hook-widget line-pre-redraw _qrepeat_live_hints