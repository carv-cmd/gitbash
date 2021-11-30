#!/bin/bash

#        _ _   _                     _    
#   __ _(_) |_| |__ _ _ __ _ _ _  __| |_  
#  / _` | |  _| '_ \ '_/ _` | ' \/ _| ' \ 
#  \__, |_|\__|_.__/_| \__,_|_||_\__|_||_|
#  |___/                                  
#
# git-branches.sh: The stupid git branch manager

MAINS='main'
CW_BRANCH="$(git branch --show-current)"
GIT_ORIGIN=${ORIGIN:-origin}
GIT_BRANCH=${BRANCH:-}

Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
The stupid git branch manager.
usage: $PROGNAME [-b|--branch][-C|--ctrack][-D|--delete][-M|--merge] NAME

Mode Flags:
 -a, --all      Shortcut for \`git branch --all -vv\`
 -b, --branch   Checkout new branch NAME from CW_BRANCH locally.
 -C, --ctrack   Same as --branch + git pushes branch NAME upstream.
 -D, --delete   (CAUTION) Delete all NAME local and remote branches.
 -M, --merge    Merge NAME into current working branch.
 --dry          Echo commands that will be executed.
 -h, --help     Display this help message and exit.

Environment:
============
ORIGIN: 
 Used in \`git remote-ops ORIGIN/name\`.
 Can only be set through env variable.

BRANCH: 
 Specifying -b, --branch overrides this.

EOF
}

Error () {
    if [ -n "$1" ]; then
        echo -e "error: $1\n" > /dev/stderr 
    else
        Usage > /dev/stderr
    fi
    exit 1
}

Branch_validator () {
    #if git branch --list | grep -qE "^\* $GIT_BRANCH"; then
    local ACTION="$1"
    if [ "$GIT_BRANCH" == "$CW_BRANCH" ]; then
        berr="${ACTION}($GIT_BRANCH) == current($CW_BRANCH)
        \rLocal Branches:\n`git branch --list`"
        Error "$berr"
    elif ! git branch --list | grep -q $GIT_BRANCH; then
        Error "branch[ $GIT_BRANCH ]: doesn't exist"
    fi
}

Branch_cleanup () {
    # Delete local branch, remote branch
    if [[ "$GIT_BRANCH" =~ ^$MAINS$ ]]; then
        Error 'protect: main: exiting'
    fi
    Branch_validator 'delete'
    $sh_c "git branch -d $GIT_BRANCH" && 
        $sh_c "git branch -d -r $GIT_ORIGIN/$GIT_BRANCH" &&
        $sh_c "git push $GIT_ORIGIN --delete $GIT_BRANCH"
}

Branch_merge () {
    Branch_validator 'merge'
    if $sh_c "git merge $GIT_BRANCH"; then
        if $sh_c "git push $GIT_ORIGIN $CW_BRANCH"; then
            read -p "Reset: $GIT_BRANCH: (y/n)?: "
            if [[ "$REPLY" =~ ^(y|yes)$ ]]; then
                Branch_chkout_track '--track'
            fi
        fi
    fi
}

Branch_chkout_track () {
    # Checkout $GIT_BRANCH from $CW_BRANCH.
    local TRACK=${1:-}
    if $sh_c "git checkout -B $GIT_BRANCH $TRACK"; then
        if [ "$TRACK" ]; then
            $sh_c "git push $GIT_ORIGIN $GIT_BRANCH"
        fi
    fi
}

Set_branch () {
    # $BRANCH name can only be set once.
    if [ ! "$1" ]; then
        return 1
    elif [[ "$1" =~ ^-(o|b|C|D|\-origin|\-branch|\-ctrack|\-delete)$ ]]; then
        Error "Flag given as argument: $1 ?"
    elif [ ! "$GIT_BRANCH" ]; then
        GIT_BRANCH="$1"
    fi
}

Parse_args () {
    local iflag=
    while [ -n "$1" ]; do
        iflag="$1"; shift
        case "$iflag" in 
            -a | --all )  git branch --all -vv; exit;;
            -b | --branch )  MODE='checkout';;
            -C | --ctrack )  MODE='ctrack';;
            -D | --delete )  MODE='delete';;
            -M | --merge )  MODE='merge';;
            --dry )  sh_c='echo'; continue;;
            -h | --help )  Error;;
            * )  Error 'invalid argument';;
        esac
        Set_branch "$1" && shift
    done

    local BRANCH_REGEX='^([[:alnum:]]|\-|\_|\.)+$'
    if [[ "$GIT_BRANCH" =~ ^--(dry|all)$ ]]; then
        Error 'NAME == --dry?'
    elif [ ! "$GIT_BRANCH" ]; then 
        Error 'No branch name given'
    elif [[ ! "$GIT_BRANCH" =~ $BRANCH_REGEX ]]; then
        Error "regex: $GIT_BRANCH !match: $BRANCH_REGEX"
    fi
}

sh_c='sh -c'
MODE=
if Parse_args "$@"; then
    case "$MODE" in
        checkout )  Branch_chkout_track;;
        ctrack )  Branch_chkout_track '--track';;
        delete ) Branch_cleanup;;
        merge )  Branch_merge;;
        * ) Error "FatalUnexpected";;
    esac
fi

