#!/bin/bash

#       _ _                   
#  __ _(_) |_ _ __  __ _ _ _  
# / _` | |  _| '  \/ _` | ' \ 
# \__, |_|\__|_|_|_\__,_|_||_|
# |___/                       
#

GITBASH=${GITBASH:-~/bin/gitbash/bin}
ECHO=${ECHO:-}
export ECHO

FLAG=$1; shift
ARGS="$@"


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
setup: $PROGNAME [install-gh-cli]|[users] OPTION
usage: $PROGNAME [upstream][repo]|[branch]|[commit] OPTION

Run \`$PROGNAME <subcommand> --help\` for specific details.

Subcommands:
 repo               Manage upstream repositories.
 branch             Manage local and remote branches.
 commit             Git add/commit/push wrapper.
 users              User config and authentication.
 view               View your Github.com repositories.
 get-gh-cli         Install the Github CLI client.
 help               Print this help message and exit.

EOF
exit 1
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    exit 1
}

run_subcommand () {
    if ! validate_command; then
        Error "$FLAG: doesn't exist"
    else
        $GITMAN "$ARGS"
    fi
}

validate_command () {
    if [ ! -f "$GITMAN" ]; then
        return 1
    else
        return 0
    fi
}

if [ ! "$FLAG" ]; then
    Usage
elif [[ "$FLAG" =~ ^-{0,2}h(elp)?$ ]]; then
    Usage
else
    GITMAN=$GITBASH/$FLAG.sh
fi

run_subcommand

