# it would be worth considering a more maintable way of handling files scoped to specific hostnames
if [[ $(hostname) == "slyo.lon.corp.google.com" ]]; then
    source /etc/bash_completion.d/hgd 2> /dev/null
    source /etc/bash_completion.d/g4d 2> /dev/null
fi