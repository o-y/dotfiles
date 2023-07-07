function rmuntr() {
    hg st -un | xargs rm
}

function revert() {
    echo "[info] hg revert -r p4head $1"
    hg revert -r p4head $1
}