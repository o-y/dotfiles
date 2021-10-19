#!/bin/sh

# author: https://gitlab.com/phoneybadger/pokemon-colorscripts

PATH_TO_SCRIPT=`realpath -s "$0"`
PATH_TO_SCRIPT_DIR=`dirname "$PATH_TO_SCRIPT"`

if [[ `uname` == 'Darwin' ]]
then
    cat $(find $PATH_TO_SCRIPT_DIR/asciiart -type f | shuf -n 1)
fi
