##
## qlock - File/Alias Permission Locker
##
typeset -gA _QLOCK_ALIASES
_QLOCK_ALIASES=(
    # because various installers find it fit to
    # fuck the contents of my zshrc and zshenv
    # files.
    "zsh"   "$HOME/.zshrc $HOME/.zshenv"
)
qlock() {
    local usage() {
        echo "qlock - File Permission Locker"
        echo "Usage: qlock <on|off|status> <target>"
        echo "  on        removes write permissions (chmod a-w)"
        echo "  off       restores user write permissions (chmod u+w)"
        echo "  status    checks current writability"
        echo "  target    a file path, directory, or alias"
        echo ""
        echo "Defined Aliases:"
        for key val in "${(@kv)_QLOCK_ALIASES}"; do
            printf "  %-9s -> %s\n" "$key" "$val"
        done
    }

    if [[ $# -lt 2 ]]; then
        usage
        return 1
    fi

    local action=$1
    local target=$2
    local paths=()

    if [[ -n "${_QLOCK_ALIASES[$target]}" ]]; then
        paths=(${(z)_QLOCK_ALIASES[$target]})
    else
        paths=("$target")
    fi

    for item in "${paths[@]}"; do
        item=${~item}

        if [[ ! -e "$item" ]]; then
            echo "[qlock] error: '$item' does not exist"
            continue
        fi

        case "$action" in
            "on")
                chmod a-w "$item"
                echo "[qlock] locked: $item (a-w)"
                ;;
            "off")
                chmod u+w "$item"
                echo "[qlock] unlocked: $item (u+w)"
                ;;
            "status")
                if [[ -w "$item" ]]; then
                    echo "[qlock] WRITABLE:   $item"
                else
                    echo "[qlock] READ-ONLY:  $item"
                fi
                ;;
            *)
                echo "[qlock] error: unknown action '$action'"
                usage
                return 1
                ;;
        esac
    done
}
_qlock() {
    local line
    _arguments -C \
        "1:action:(on off status)" \
        "2:target:->targets"

    case $state in
        targets)
            _alternative \
                "aliases:alias:(${(k)_QLOCK_ALIASES})" \
                "files:file:_files"
            ;;
    esac
}
compdef _qlock qlock

##
## _qlock_live_hints
##
_qlock_live_hints() {
    if [[ "$BUFFER" == qlock\ * ]]; then
        _QLOCK_HINT_ACTIVE=1
        local -a current_words
        current_words=(${(z)BUFFER})
        
        local word_count=${#current_words[@]}
        [[ "$BUFFER" =~ " $" ]] && ((word_count++))

        local hint=""
        case $word_count in
            2) 
                hint="󰁔 action (on | off | status)" 
                ;;
            3) 
                hint="󰁔 target (<file-path> | <alias>)" 
                ;;
        esac

        if [[ -n "$hint" ]]; then
            zle -M "$hint"
        else
            zle -M "" 
        fi
    elif (( _QLOCK_HINT_ACTIVE == 1 )); then
        _QLOCK_HINT_ACTIVE=0
        zle -M ""
    fi
}

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _qlock_live_hints