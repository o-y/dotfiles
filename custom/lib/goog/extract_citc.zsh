function regexM { 
    gawk 'match($0,/'$1'/, ary) {print ary['${2:-'1'}']}'; 
}

function extract_citc_client_from_path {
    if [[ "$(pwd)" =~ ^\/google\/src\/cloud\/slyo\/(.*?)\/google3$ ]]; then
        echo "$(pwd)" | regexM '\/google\/src\/cloud\/slyo\/(.*?)\/google3'
    fi
}