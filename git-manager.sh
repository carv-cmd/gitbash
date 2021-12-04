#!/bin/bash

#       _ _                   
#  __ _(_) |_ _ __  __ _ _ _  
# / _` | |  _| '  \/ _` | ' \ 
# \__, |_|\__|_|_|_\__,_|_||_|
# |___/                       
# 
# Run ./git-{repos.sh,branch.sh,commit.sh,users,install-gh-cli}.sh

GITBASH=~/bin/gitbash
GIT_SUBCMD="git-$1.sh"; shift
GITMAN=$GITBASH/$GIT_SUBCMD


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [repo][branch][commit] OPTION

Run \`$PROGNAME <subcommand> --help\` for specific details.

Subcommands:
 repo               Git upstream repo manager. 
 branch             Git branch manager.
 commit             Git commit manager.
 users              Git user configurations.
 install-gh-cli     Install the Github CLI.
 help               Print this help message and exit.

EOF
exit 1
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    exit 1
}

execute_subcommand () {
    echo
    $sh_c "$GITMAN"

}


if [[ "$GIT_SUBCMD" =~ ^help$ ]]; then
    Usage
elif [ ! -f "$GITMAN" ]; then
    Error "$GITMAN: doesn't exist"
else
    execute_subcommand "$@"
fi




























