# ==========================================
# qfile.zsh - File Iteration & Conversion
# ==========================================

##
## qfile - Main Wrapper
##
qfile() {
    emulate -L zsh

    local usage() {
        echo "qfile - File Iteration & Conversion Utility"
        echo "Usage: qfile <command> [options] [...]"
        echo ""
        echo "Commands:"
        echo "  each      Batch command execution"
        echo "  convert   Media converter wrapper"
        echo "  compress  In-place or target-based media compression"
        echo ""
        echo "Run 'qfile <command> --help' for more details."
    }

    if [[ $# -eq 0 ]]; then
        usage
        return 1
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        each)
            __qfile_each "$@"
            ;;
        convert)
            __qfile_convert "$@"
            ;;
        compress)
            __qfile_compress "$@"
            ;;
        -h|--help|help)
            usage
            return 0
            ;;
        *)
            echo "[qfile] error: unknown command '$cmd'" >&2
            usage
            return 1
            ;;
    esac
}

##
## qfile each - Batch Command Execution
##
__qfile_each() {
    emulate -L zsh
    setopt local_options local_traps no_monitor
    
    local usage() {
        echo "qfile each - Batch Command Execution"
        echo "Usage: qfile each [options] <globs> [--] <command...>"
        echo ""
        echo "Options:"
        echo "  -t, --tasks=<n>  Max parallel tasks (defaults to 1 for safety)."
        echo "                   Set to 0 or 'auto' to automatically use all CPU cores."
        echo "  -R, --recursive  Search directories recursively (removes max-depth 1)."
        echo "  -d, --dry-run    Print simulated executions without running them."
        echo ""
        echo "Placeholders:"
        echo "  {}          Relative path  (e.g. ./foo.png)"
        echo "  {.}         Path w/o ext   (e.g. ./foo)"
        echo "  {/}         Basename       (e.g. foo.png)"
        echo "  {/.}        Base w/o ext   (e.g. foo)"
        echo "  {a}         Absolute path  (e.g. /path/to/foo.png)"
        echo "  {a.}        Abs w/o ext    (e.g. /path/to/foo)"
    }

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        return 0
    fi

    local dry_run=0 recursive=0 max_tasks=1 patterns=""
    local -a raw_cmd=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --)
                shift
                if [[ -z "$patterns" ]]; then
                    if [[ $# -eq 0 ]]; then usage; return 1; fi
                    patterns="$1"
                    shift
                fi
                raw_cmd=("$@")
                break
                ;;
            -d|--dry-run) dry_run=1; shift ;;
            -R|--recursive) recursive=1; shift ;;
            -t|--tasks)
                if [[ -n "$2" && ( "$2" =~ ^[0-9]+$ || "$2" == "auto" ) ]]; then
                    max_tasks="$2"; shift 2
                else
                    echo "[qfile each] error: -t/--tasks requires a numeric argument or 'auto'." >&2; return 1
                fi
                ;;
            --tasks=*)
                local num="${1#--tasks=}"
                if [[ "$num" =~ ^[0-9]+$ || "$num" == "auto" ]]; then
                    max_tasks="$num"; shift
                else
                    echo "[qfile each] error: --tasks= requires a numeric argument or 'auto'." >&2; return 1
                fi
                ;;
            -t*)
                local num="${1#-t}"
                if [[ "$num" =~ ^[0-9]+$ || "$num" == "auto" ]]; then
                    max_tasks="$num"; shift
                else
                    echo "[qfile each] error: -t requires a numeric argument or 'auto'." >&2; return 1
                fi
                ;;
            -*)
                if [[ -z "$patterns" ]]; then
                    echo "[qfile each] error: unknown option '$1'" >&2; usage; return 1
                else
                    raw_cmd=("$@"); break
                fi
                ;;
            *)
                if [[ -z "$patterns" ]]; then
                    patterns="$1"; shift
                else
                    raw_cmd=("$@"); break
                fi
                ;;
        esac
    done

    if [[ -z "$patterns" || ${#raw_cmd[@]} -eq 0 ]]; then
        usage
        return 1
    fi

    if [[ "$max_tasks" == "auto" ]] || (( max_tasks == 0 )); then
        if command -v nproc >/dev/null 2>&1; then max_tasks=$(nproc)
        elif command -v sysctl >/dev/null 2>&1; then max_tasks=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
        else max_tasks=4; fi
        (( max_tasks == 0 )) && max_tasks=4
    fi

    local fd_cmd="fd"
    if ! command -v "$fd_cmd" >/dev/null 2>&1; then
        if command -v fdfind >/dev/null 2>&1; then fd_cmd="fdfind"
        else echo "[qfile each] error: 'fd' required." >&2; return 1; fi
    fi

    local -a fd_opts=(--type f --hidden --no-ignore)
    (( ! recursive )) && fd_opts+=(--max-depth 1)

    local -a files 
    typeset -U files

    local -a pat_array=()
    for p in "${(@s/,/)patterns}"; do
        while [[ "$p" == [[:space:]]* ]]; do p="${p#?}"; done
        while [[ "$p" == *[[:space:]] ]]; do p="${p%?}"; done
        [[ -n "$p" ]] && pat_array+=("$p")
    done

    for p in "${pat_array[@]}"; do
        while IFS= read -r -d '' file || [[ -n "$file" ]]; do
            [[ -n "$file" ]] && files+=("$file") 
        done < <("$fd_cmd" "${fd_opts[@]}" --glob "$p" 2>/dev/null -0)
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "[qfile each] No files matched pattern(s): '$patterns'"
        return 0
    fi

    local esc=$'\e' reset="${esc}[0m" dim="${esc}[2m" green="${esc}[32m" cyan="${esc}[36m" magenta="${esc}[35m"

    if (( dry_run )); then
        local w_txt="Sequential Execution"
        (( max_tasks > 1 )) && w_txt="${max_tasks} Parallel Tasks"
        echo "${magenta}=== qfile each Dry Run (${#files[@]} files, $w_txt) ===${reset}\n"
    elif (( max_tasks > 1 )); then
        echo "${dim}[qfile each] Processing ${#files[@]} files concurrently across ${max_tasks} tasks...${reset}\n"
        local -x QFILE_EACH_PARALLEL=1
    fi

    zmodload zsh/zselect 2>/dev/null || true
    local -a active_pids=()
    
    if (( max_tasks > 1 && ! dry_run )); then
        trap '
            if (( ${#active_pids[@]} > 0 )); then
                echo "\n${magenta}[qfile each] Interrupted! Terminating...${reset}" >&2
                builtin kill -TERM "${active_pids[@]}" 2>/dev/null
                wait "${active_pids[@]}" 2>/dev/null
            fi
            return 130
        ' INT TERM
    fi

    local P_BASE_NO_EXT="{/.}"   M_BASE_NO_EXT="@@Q_BASE_NO_EXT@@"
    local P_BASE="{/}"           M_BASE="@@Q_BASE@@"
    local P_ABS_NO_EXT="{a.}"    M_ABS_NO_EXT="@@Q_ABS_NO_EXT@@"
    local P_ABS="{a}"            M_ABS="@@Q_ABS@@"
    local P_NO_EXT="{.}"         M_NO_EXT="@@Q_NO_EXT@@"
    local P_FULL="{}"            M_FULL="@@Q_FULL@@"

    for file in "${files[@]}"; do
        local -a exec_cmd=()
        local has_placeholder=0 f_full="$file"
        
        [[ "$f_full" != ./* && "$f_full" != /* ]] && f_full="./$f_full"

        local f_base="${f_full:t}" f_no_ext="${f_full:r}" f_base_no_ext="${f_base:r}" f_abs="${f_full:a}" f_abs_no_ext="${f_abs:r}"        

        for arg in "${raw_cmd[@]}"; do
            if [[ "$arg" == *"{}"* || "$arg" == *"{.}"* || "$arg" == *"{/}"* || "$arg" == *"{/.}"* || "$arg" == *"{a}"* || "$arg" == *"{a.}"* ]]; then
                has_placeholder=1
                local sub="$arg"
                sub="${sub//$P_BASE_NO_EXT/$M_BASE_NO_EXT}"
                sub="${sub//$P_BASE/$M_BASE}"
                sub="${sub//$P_ABS_NO_EXT/$M_ABS_NO_EXT}"
                sub="${sub//$P_ABS/$M_ABS}"
                sub="${sub//$P_NO_EXT/$M_NO_EXT}"
                sub="${sub//$P_FULL/$M_FULL}"

                sub="${sub//$M_BASE_NO_EXT/$f_base_no_ext}"
                sub="${sub//$M_BASE/$f_base}"
                sub="${sub//$M_ABS_NO_EXT/$f_abs_no_ext}"
                sub="${sub//$M_ABS/$f_abs}"
                sub="${sub//$M_NO_EXT/$f_no_ext}"
                sub="${sub//$M_FULL/$f_full}"
                exec_cmd+=("$sub")
            else
                exec_cmd+=("$arg")
            fi
        done

        (( ! has_placeholder )) && exec_cmd+=("$f_full")

        if (( dry_run )); then
            local display_cmd="${green}${(q)exec_cmd[1]}${reset}"
            for ((i=2; i<=${#exec_cmd[@]}; i++)); do
                local a="${exec_cmd[i]}"
                if (( i > ${#raw_cmd[@]} )) || [[ "$a" != "${raw_cmd[i]}" ]]; then
                    display_cmd+=" ${cyan}${(q)a}${reset}"
                else
                    display_cmd+=" ${dim}${(q)a}${reset}"
                fi
            done
            echo " ${magenta}Target:${reset} ${file}\n ${magenta}Run:${reset}    ${display_cmd}\n"
        else
            if (( max_tasks > 1 )); then
                "${exec_cmd[@]}" &
                active_pids+=($!)
                
                while (( ${#active_pids[@]} >= max_tasks )); do
                    local -a next_pids=()
                    jobs >/dev/null 2>&1
                    for pid in "${active_pids[@]}"; do
                        builtin kill -0 "$pid" 2>/dev/null && next_pids+=("$pid")
                    done
                    active_pids=("${next_pids[@]}")
                    
                    if (( ${#active_pids[@]} >= max_tasks )); then
                        if (( $+builtins[zselect] )); then zselect -t 5
                        else sleep 0.05 2>/dev/null || sleep 1; fi
                    fi
                done
            else
                "${exec_cmd[@]}"
            fi
        fi
    done

    if (( ! dry_run && max_tasks > 1 && ${#active_pids[@]} > 0 )); then
        wait "${active_pids[@]}" 2>/dev/null
    fi
}

##
## qfile convert - Thin Media Converter Wrapper
##
__qfile_convert() {
    emulate -L zsh
    
    local usage() {
        echo "qfile convert - Media Converter"
        echo "Usage: qfile convert [-rm] <input_file> <output_file> [backend_args...]"
    }

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then usage; return 0; fi

    local rm_flag=0
    local -a args=()

    for arg in "$@"; do
        if [[ "$arg" == "-rm" || "$arg" == "--rm" ]]; then rm_flag=1
        else args+=("$arg"); fi
    done
    set -- "${args[@]}"

    if [[ $# -lt 2 ]]; then usage; return 1; fi

    local file_in="$1" file_out="$2"
    shift 2

    if [[ ! -f "$file_in" ]]; then
        echo "[qfile convert] error: input file '$file_in' does not exist." >&2; return 1
    fi
    if [[ "$file_in" == "$file_out" ]]; then
        echo "[qfile convert] error: input and output filenames must be different." >&2; return 1
    fi
    if [[ -e "$file_out" ]]; then
        echo "[qfile convert] error: output file '$file_out' already exists." >&2; return 1
    fi

    local is_video=0
    for ext in "${file_in:e:l}" "${file_out:e:l}"; do
        case "$ext" in
            mp4|mkv|mov|avi|webm|flv|wmv|ts|mp3|wav|m4a|aac|flac|ogg|opus|m4v) is_video=1 ;;
        esac
    done

    local cyan=$'\e[36m' reset=$'\e[0m' dim=$'\e[2m' red=$'\e[31m' green=$'\e[32m'
    local exit_code=0

    if (( is_video )); then
        if ! command -v ffmpeg >/dev/null 2>&1; then
            echo "[qfile convert] error: 'ffmpeg' required." >&2; return 1
        fi
        
        # Determine caller context to format UI strictly if wrapped by a parent qfile pipeline
        if [[ -z "$QFILE_COMPRESS_PIPE" ]]; then
            echo "${cyan}=> ffmpeg:${reset} ${file_in:t} ${dim}->${reset} ${file_out:t}"
        fi
        
        local -a ffmpeg_flags=(-hide_banner -loglevel error)
        [[ -z "$QFILE_EACH_PARALLEL" ]] && ffmpeg_flags+=(-stats)

        ffmpeg "${ffmpeg_flags[@]}" -i "$file_in" "$@" "$file_out" </dev/null
        exit_code=$?
    else
        local cmd="convert"
        if command -v magick >/dev/null 2>&1; then cmd="magick"
        elif ! command -v convert >/dev/null 2>&1; then
            echo "[qfile convert] error: 'magick/convert' required." >&2; return 1
        fi
        
        if [[ -z "$QFILE_COMPRESS_PIPE" ]]; then
            echo "${cyan}=> ${cmd}:${reset} ${file_in:t} ${dim}->${reset} ${file_out:t}"
        fi
        
        "$cmd" "$file_in" "$@" "$file_out"
        exit_code=$?
    fi

    if [[ -z "$QFILE_COMPRESS_PIPE" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            if (( rm_flag )); then
                rm -f "$file_in" && echo "   ${green}✓${reset} ${dim}Success (Deleted original: ${file_in:t})${reset}" || echo "   ${red}Warning: Failed to delete original.${reset}" >&2
            else
                echo "   ${green}✓${reset} ${dim}Success${reset}"
            fi
        else
            echo "   ${red}error: Conversion failed.${reset}" >&2
            [[ -f "$file_out" ]] && rm -f "$file_out"
        fi
    fi
    
    # Let parent handle partial cleanup if piped
    [[ $exit_code -ne 0 && -n "$QFILE_COMPRESS_PIPE" && -f "$file_out" ]] && rm -f "$file_out"
    return $exit_code
}

##
## qfile compress - In-place or target-based media compression
##
__qfile_compress() {
    emulate -L zsh

    local usage() {
        echo "qfile compress - Image/Media Compression"
        echo "Usage: qfile compress [-r|--replace] <file> <quality>"
        echo ""
        echo "Options:"
        echo "  -r, --replace   Overwrite the original file instead of creating a new one."
        echo ""
        echo "Note: 'quality' maps to '-quality' for images and '-crf' for video."
    }

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then usage; return 0; fi

    local replace=0
    local -a args=()

    for arg in "$@"; do
        if [[ "$arg" == "-r" || "$arg" == "--replace" ]]; then
            replace=1
        else
            args+=("$arg")
        fi
    done
    set -- "${args[@]}"

    if [[ $# -ne 2 ]]; then
        usage
        return 1
    fi

    local file="$1"
    local quality="$2"

    if [[ ! -f "$file" ]]; then
        echo "[qfile compress] error: file '$file' not found." >&2
        return 1
    fi

    # Map backend quality directives natively
    local -a backend_args=()
    local ext="${file:e:l}"
    if [[ "$ext" =~ ^(mp4|mkv|mov|avi|webm|flv|wmv|ts|m4v)$ ]]; then
        backend_args=(-crf "$quality")
    else
        backend_args=(-quality "$quality")
    fi

    local cyan=$'\e[36m' reset=$'\e[0m' dim=$'\e[2m' green=$'\e[32m' red=$'\e[31m'
    local tmp_out="${file:h}/.qfile_tmp_${file:t}"
    local final_out=""
    
    if (( replace )); then
        final_out="$file"
        echo "${cyan}=> compress:${reset} ${file:t} ${dim}(Quality: ${quality}, In-Place)${reset}"
    else
        final_out="${file:r}_${quality}.${file:e}"
        echo "${cyan}=> compress:${reset} ${file:t} ${dim}->${reset} ${final_out:t} ${dim}(Quality: ${quality})${reset}"
    fi

    # Suppress verbose stdout from the underlying generic converter
    local -x QFILE_COMPRESS_PIPE=1 

    # Pipe to the API. If replace=1, write to tmp file first to prevent unbuffered memory collisions.
    local target_file=$(( replace ? tmp_out : final_out ))

    if __qfile_convert "$file" "$target_file" "${backend_args[@]}"; then
        if (( replace )); then
            mv -f "$tmp_out" "$final_out"
            echo "   ${green}✓${reset} ${dim}Success (Overwrote original)${reset}"
        else
            echo "   ${green}✓${reset} ${dim}Success${reset}"
        fi
    else
        echo "   ${red}error: Compression failed.${reset}" >&2
        return 1
    fi
}

##
## qfile - Zsh Completions
##
_qfile() {
    local context state state_descr line
    typeset -A opt_args

    _arguments -C \
        '1: :->cmds' \
        '*:: :->args'

    case $state in
        cmds)
            local -a commands=(
                'each:Batch command execution'
                'convert:Thin media converter wrapper'
                'compress:In-place or target-based media compression'
            )
            _describe -t commands "qfile command" commands
            ;;
        args)
            case $line[1] in
                each)
                    _arguments -S \
                        '(-d --dry-run)'{-d,--dry-run}'[Print simulated executions without running them]' \
                        '(-R --recursive)'{-R,--recursive}'[Search directories recursively]' \
                        '(-t --tasks)'{-t,--tasks}'[Max concurrent tasks (default: 1, use 0/auto for max)]:tasks:(1 2 4 8 auto)' \
                        '1:patterns (comma-separated): ' \
                        '*::command:_normal'
                    ;;
                convert)
                    _arguments -S \
                        '(-rm --rm)'{-rm,--rm}'[Delete input file upon successful conversion]' \
                        '1:input file:_files' \
                        '2:output file:_files' \
                        '*::backend args:_normal'
                    ;;
                compress)
                    _arguments -S \
                        '(-r --replace)'{-r,--replace}'[Overwrite the original file instead of creating a new one]' \
                        '1:file:_files' \
                        '2:quality: '
                    ;;
            esac
            ;;
    esac
}
compdef _qfile qfile