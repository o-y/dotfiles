# outputs current citc client

if [[ `uname` == 'Linux' ]] then
    function regexM { 
        gawk 'match($0,/'$1'/, ary) {print ary['${2:-'1'}']}'; 
    }

    prompt_citc() {
        if [[ "$(pwd)" =~ ^\/google\/src\/cloud\/slyo\/(.*?)\/google3$ ]]; then
            citc=$(echo "$(pwd)" | regexM '\/google\/src\/cloud\/slyo\/(.*?)\/google3')
            p10k segment -t "citc:(%{$fg[green]%}$citc%{$reset_color%})"
        fi
    }
fi
