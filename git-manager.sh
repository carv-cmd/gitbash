#!/bin/bash

#       _ _                   
#  __ _(_) |_ _ __  __ _ _ _  
# / _` | |  _| '  \/ _` | ' \ 
# \__, |_|\__|_|_|_\__,_|_||_|
# |___/                       
# 
# git-mngr.sh: 

GITBASH=~/bin/gitbash/git
EXECUTE="$1"
shift

Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [repo][branch][commit] OPTION

Run any $PROGNAME subcommand with --help flag to see its options.

Options:
 repo       Git repository manager. 
 branch     Git branch manager.
 commit     Git commit manager.
 help       Print this help message and exit.

EOF
exit 1
}

case "$EXECUTE" in
    repo ) $GITBASH-repos.sh "$@";;
    branch ) $GITBASH-branches.sh "$@";;
    commit ) $GITBASH-commits.sh "$@";;
    * ) Usage;;
esac


