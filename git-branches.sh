#!/bin/bash

#       _ _   _                  
#  __ _(_) |_| |__ _ _ __ _ _ _  
# / _` | |  _| '_ \ '_/ _` | ' \ 
# \__, |_|\__|_.__/_| \__,_|_||_|
# |___/                          
# 
# The stupid git branch manager

MASTER='main'
ORIGIN=${ORIGIN:-origin}
NEW_BRANCH=${NEW_BRANCH:-}
CURRENT_BRANCH="$(git branch --show-current)"


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME

 $PROGNAME [--checkout]|[--checkout-track]|[--delete]|[--merge] [--dry] BRANCH_NAME
 $PROGNAME [-a|--all]

Options:
 -c, --checkout         Checkout new BRANCH_NAME from CURRENT_BRANCH.
 -C, --checkout-track   Identical to -c, but pushes BRANCH_NAME upstream.
 -D, --delete           Delete all local and remote BRANCH_NAME's.
 -M, --merge            Merge BRANCH_NAME into CURRENT_BRANCH.
 -a, --all              Shortcut for \`git branch --all -vv\`
 -d, --dry              Echo commands that would be executed.
 -h, --help             Display this help message and exit.

==========
For defaults set the following in your shell.
==========
ORIGIN: 
 Can only be set through environment.
BRANCH: 
 Command line arguments take precedence.

EOF
exit
}

Error () {
    echo -e "error: $1\n" > /dev/stderr 
    exit 1
}

Valid_branch () {
    local ACTION="$1"
    if [ "$NEW_BRANCH" == "$CURRENT_BRANCH" ]; then
        Error "$ACTION($NEW_BRANCH) == current($CURRENT_BRANCH)"
    elif ! git branch --list | grep -q $NEW_BRANCH; then
        Error "branch[ $NEW_BRANCH ]: doesn't exist"
    fi
}

Stale_cleaner () {
    # Delete all local and remote references to stale branch.
    Valid_branch 'delete'
    $sh_c "git branch -d $NEW_BRANCH" && 
        $sh_c "git branch -d -r $ORIGIN/$NEW_BRANCH" &&
        $sh_c "git push $ORIGIN --delete $NEW_BRANCH"
}

Merger () {
    Valid_branch 'merge'
    if $sh_c "git merge $NEW_BRANCH"; then
        if git branch --list -r | grep -q ^*$NEW_BRANCH*$; then
            $sh_c "git push $ORIGIN $CURRENT_BRANCH" && New_branch '--track'
        else
            New_branch
        fi
    fi
}

New_branch () {
    local TRACK=${1:-}
    if $sh_c "git checkout -B $NEW_BRANCH $TRACK"; then
        if [ "$TRACK" ]; then
            $sh_c "git push $ORIGIN $NEW_BRANCH"
        fi
    fi
}

Parse_args () {
    for arg in "$@"; do
        case "$arg" in 
            -a | --all )  git branch --all -vv; exit;;
            -c | --checkout )  MODE='checkout';;
            -C | --checkout-track )  MODE='ctrack';;
            -D | --delete )  MODE='delete';;
            -M | --merge )  MODE='merge';;
            -d | --dry )  sh_c='echo'; continue;;
            -h | --help )  Usage > /dev/stderr;;
            * )  [[ ! "$arg" =~ ^--?[A-Za-z]+$ ]] && 
                NEW_BRANCH="$arg";;
        esac
    done
    if [ ! "$NEW_BRANCH" ]; then
        Error 'branch name unset.'
    fi
}

MODE=
sh_c='sh -c'
Parse_args "$@"
case "$MODE" in
    checkout )  New_branch;;
    ctrack )  New_branch '--track';;
    delete ) Stale_cleaner;;
    merge )  Merger;;
    * ) Error "UnexpectedError";;
esac

