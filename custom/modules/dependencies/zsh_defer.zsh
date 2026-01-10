'builtin' 'local' '-a' '_zsh_defer_opts'
[[ ! -o 'aliases'         ]] || _zsh_defer_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || _zsh_defer_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || _zsh_defer_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

typeset -ga _zsh_defer_tasks

function zsh-defer-reset-autosuggestions_() {
  unsetopt warn_nested_var
  orig_buffer=
  orig_postdisplay=
}
zle -N zsh-defer-reset-autosuggestions_

function _zsh-defer-schedule() {
  local fd
  if [[ $1 == 0 ]]; then
    exec {fd}</dev/null
  else
    zmodload zsh/zselect
    exec {fd}< <(zselect -t $1)
  fi
  zle -F $fd _zsh-defer-resume
}

function _zsh-defer-resume() {
  emulate -L zsh
  zle -F $1
  exec {1}>&-
  while (( $#_zsh_defer_tasks && !KEYS_QUEUED_COUNT && !PENDING )); do
    local delay=${_zsh_defer_tasks[1]%% *}
    local task=${_zsh_defer_tasks[1]#* }
    if [[ $delay == 0 ]]; then
      _zsh-defer-apply $task
      shift _zsh_defer_tasks
    else
      _zsh-defer-schedule $delay
      _zsh_defer_tasks[1]="0 $task"
      return 0
    fi
  done
  (( $#_zsh_defer_tasks )) && _zsh-defer-schedule 0
  return 0
}
zle -N _zsh-defer-resume

function _zsh-defer-apply() {
  local opts=${1%% *}
  local cmd=${1#* }
  local dir=${(%):-%/}
  local -i fd1=-1 fd2=-1
  [[ $opts == *1* ]] && exec {fd1}>&1 1>/dev/null
  [[ $opts == *2* ]] && exec {fd2}>&2 2>/dev/null
  {
    local zsh_defer_options=$opts  # this is a part of public API
    () {
      if [[ $opts == *c* ]]; then
        eval $cmd
      else
        "${(@Q)${(z)cmd}}"
      fi
    }
    emulate -L zsh
    local hook hooks
    [[ $opts == *d* && ${(%):-%/} != $dir ]] && hooks+=($chpwd  $chpwd_functions)
    [[ $opts == *m*                       ]] && hooks+=($precmd $precmd_functions)
    for hook in $hooks; do
      (( $+functions[$hook] )) || continue
      $hook
      emulate -L zsh
    done
    [[ $opts == *s* && $+ZSH_AUTOSUGGEST_STRATEGY    == 1 ]] && zle zsh-defer-reset-autosuggestions_
    [[ $opts == *z* && $+_ZSH_HIGHLIGHT_PRIOR_BUFFER == 1 ]] && _ZSH_HIGHLIGHT_PRIOR_BUFFER=
    [[ $opts == *p* ]] && zle reset-prompt
    [[ $opts == *r* ]] && zle -R
  } always {
    (( fd1 >= 0 )) && exec 1>&$fd1 {fd1}>&-
    (( fd2 >= 0 )) && exec 2>&$fd2 {fd2}>&-
  }
}

function zsh-defer() {
  emulate -L zsh -o extended_glob
  local all=12dmszpr
  local -i delay OPTIND
  local opts=$all cmd opt OPTARG match mbegin mend
  while getopts ":hc:t:a$all" opt; do
    case $opt in
      *h)
        return 0
      ;;
      c)
        if [[ $opts == *c* ]]; then
          print -r -- "zsh-defer: duplicate option: -c" >&2
          return 1
        fi
        opts+=c
        cmd=$OPTARG
      ;;
      t)
        if [[ $OPTARG != (|+)<->(|.<->)(|[eE](|-|+)<->) ]]; then
          print -r -- "zsh-defer: invalid -t argument: $OPTARG" >&2
          return 1
        fi
        zmodload zsh/mathfunc
        delay='ceil(100 * OPTARG)'
      ;;
      +c|+t) >&2 print -r -- "zsh-defer: invalid option: $opt"               ; return 1;;
      \?)    >&2 print -r -- "zsh-defer: invalid option: $OPTARG"            ; return 1;;
      :)     >&2 print -r -- "zsh-defer: missing required argument: $OPTARG" ; return 1;;
      a)  [[ $opts == *c*            ]] && opts=c                  || opts=            ;;
      +a) [[ $opts == *c*            ]] && opts=c$all              || opts=$all        ;;
      ?)  [[ $opts == (#b)(*)$opt(*) ]] && opts=$match[1]$match[2]                     ;;
      +?) [[ $opts != *${opt:1}*     ]] && opts+=${opt:1}                              ;;
    esac
  done
  if [[ $opts != *c* ]]; then
    cmd="${(@q)@[OPTIND,-1]}"
  elif (( OPTIND <= ARGC )); then
    print -r -- "zsh-defer: unexpected positional argument: ${*[OPTIND]}" >&2
    return 1
  fi
  [[ $opts == *p* && $+RPS1 == 0 ]] && RPS1=
  (( $#_zsh_defer_tasks )) || _zsh-defer-schedule 0
  _zsh_defer_tasks+="$delay $opts $cmd"
}

(( ${#_zsh_defer_opts} )) && setopt ${_zsh_defer_opts[@]}
'builtin' 'unset' '_zsh_defer_opts'