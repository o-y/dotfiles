function flipboolean() {
    if [ $# -lt 2 ]; then
        echo "Expected: $funcstack[1] <flag-id> [true/false]"
        return
    fi

    echo "$2"

    if [ "$2"  != 'false' ] || [ "$2"  != 'true' ]; then
        echo "Expected: $funcstack[1] <flag-id> [true/false]"
        return
    fi 
    
    adb shell am broadcast \
        -a com.google.android.gms.phenotype.FLAG_OVERRIDE \
        --es package com.google.android.googlequicksearchbox \
        --es user "\\*" \
        --esa flags $1 \
        --esa values $2 \
        --esa types boolean com.google.android.gms
}