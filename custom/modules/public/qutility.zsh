# specifies wrappers around common functionality

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
## qzshtime - Records how long it takes zsh to load
##
qzshtime() {
    shell=${1-$SHELL}
    for i in $(seq 1 8); do /usr/bin/time $shell -i -c exit; done
}

##
## qback - Send commands to the background
##
qback() {
    
}

