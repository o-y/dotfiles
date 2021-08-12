PATH_TO_SCRIPT=`realpath -s "$0"`
PATH_TO_SCRIPT_DIR=`dirname "$PATH_TO_SCRIPT"`
MODULES="$PATH_TO_SCRIPT_DIR/modules"
PRIVATE_MODULES="$PATH_TO_SCRIPT_DIR/modules/private"

for file in $MODULES/*; do source $file; done;
for file in $PRIVATE_MODULES/*; do source $file; done;
