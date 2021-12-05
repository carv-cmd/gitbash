#!/bin/bash

#       _ _                   
#  __ _(_) |_ _ __  __ _ _ _  
# / _` | |  _| '  \/ _` | ' \ 
# \__, |_|\__|_|_|_\__,_|_||_|
# |___/                       
# 
# Run ./git-{repos.sh,branch.sh,commit.sh,users,install-gh-cli}.sh

GITBASH=~/bin/gitbash/bin
GIT_SUBCMD="$1.sh"; shift
GITMAN=$GITBASH/$GIT_SUBCMD
ECHO=${ECHO:-}

Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
setup: $PROGNAME [install-gh-cli]|[users] OPTION
usage: $PROGNAME [upstream][repo]|[branch]|[commit] OPTION

Run \`$PROGNAME <subcommand> --help\` for specific details.

Subcommands:
 repo               Git upstream repo manager. 
 branch             Git branch manager.
 commit             Git commit manager.
 users              Git user configurations.
 upstream           Print all upstream gh repos owned by you.
 install-gh-cli     Install the Github CLI client.
 help               Print this help message and exit.

EOF
exit 1
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    exit 1
}

if [[ "$GIT_SUBCMD" =~ ^help.sh$ ]]; then
    Usage
elif [ ! -f "$GITMAN" ]; then
    Error "$GITMAN: doesn't exist"
fi

$GITMAN "$@"

