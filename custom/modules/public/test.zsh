# simple test script to verify completions work fine

foo() {
    local parameters=("alpha" "beta" "charlie" "delta" "echo")

    if (( $# != 5 )); then
        echo "Usage: foo <alpha> <beta> <charlie> <delta> <echo>"
        return 1
    fi

    echo "Parameters: $*"
}

_foo() {
    local -a parameters
    parameters=(
        "alpha:Description for alpha"
        "beta:Description for beta"
        "charlie:Description for charlie"
        "delta:Description for delta"
        "echo:Description for echo"
    )
    _describe 'values' parameters
}
compdef _foo foo