#!/bin/bash

#       _ _                   
#  __ _(_) |_ _ __  __ _ _ _  
# / _` | |  _| '  \/ _` | ' \ 
# \__, |_|\__|_|_|_\__,_|_||_|
# |___/                       
# 
# git-mngr.sh: 


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [repo][branch][commit] OPTION

Run any $PROGNAME subcommand with --help flag to see its options.

Managers:
 users          Git user configs.
 repos          Git repositories. 
 branches       Git branches.
 commits        Git commits.
 help           Print this help message and exit.

EOF
exit 1
}

ECHO=${ECHO:-}
export ECHO

EXECUTE="$1"; shift
subcmd=~/bin/gitbash/git-$EXECUTE.sh 

if [[ ! "$EXECUTE" =~ ^(users|repos|branches|commits)$ ]]; then
    Usage
elif [ ! -f "$subcmd" ]; then
    echo "error: $subcmd: doesn't exist"
    Usage
fi

$subcmd "$@"

