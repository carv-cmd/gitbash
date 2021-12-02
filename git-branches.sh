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
BRANCH_NAME=${BRANCH_NAME:-}
CURRENT_BRANCH="$(git branch --show-current)"

sh_c=${SHC:-}
if [ "$sh_c" ]; then
    sh_c='echo'
else
    sh_c='sh -c'
fi


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME

 $PROGNAME [-a|--all]
 $PROGNAME [-m|--merge] BRANCH_NAME
 $PROGNAME [-l|--mk-locals]|[-L|--rm-locals] BRANCH_NAME
 $PROGNAME [-r|--mk-remotes]|[-R|--rm-remotes] BRANCH_NAME

Options:
 -l, --mk-locals        Checkout new BRANCH_NAME from CURRENT_BRANCH.
 -r, --mk-remotes       Identical to -l, but pushes BRANCH_NAME upstream.
 -m, --merge            Merge BRANCH_NAME into CURRENT_BRANCH.
 -L, --rm-locals        Delete local references to BRANCH_NAME
 -R, --rm-remotes       Delete remote reference to BRANCH_NAME.
 -a, --all              Print \`git branch --all -vv\` and exit.
 -h, --help             Display this help message and exit.

=============================================
For defaults set the following in your shell.
==========
ORIGIN: 
 Can only be set through environment.
BRANCH: 
 Command line arguments take precedence.
SHC:
 Set with any value to echo commands instead of executing them.

EOF
exit
}

Error () {
    echo -e "error: $1\n" > /dev/stderr 
    exit 1
}

make_locals () {
    local TRACK=${1:-}
    $sh_c "git checkout -B $BRANCH_NAME $TRACK"
}

make_remotes () {
    if make_locals '--track'; then
        $sh_c "git push $ORIGIN $BRANCH_NAME"
    fi
}

send_upstream () {
    if [ -n "$(git remote -v)" ]; then
        $sh_c "git push $ORIGIN $CURRENT_BRANCH"
    fi
}

merge_branches () {
    if $sh_c "git merge $BRANCH_NAME"; then
        send_upstream
    fi
}

remove_locals () {
    $sh_c "git branch -d $BRANCH_NAME" 
}

remove_remotes () {
    if [ -n "$(git remtote -v)" ]; then
        $sh_c "git branch -d -r $ORIGIN/$BRANCH_NAME"
        $sh_c "git push $ORIGIN --delete $BRANCH_NAME"
    fi
}

execute_branch_task () {
    case "$BRANCH_OPERATION" in 
        -l | --mk-locals )  make_locals;;
        -r | --mk-remotes ) make_remotes;; 
        -m | --merge )  merge_branches;;
        -L | --rm-locals ) remove_locals;;
        -R | --rm-remotes )  remove_remotes;;
        -h | --help )  Usage;;
        * ) Error "unknown option: $BRANCH_OPERATION"
    esac
}

valid_name () {
    if [[ ! "$BRANCH_NAME" =~ ^[[:alnum:]]*$ ]]; then
        Error "invalid name: $1"
    else
        return 0
    fi
}


BRANCH_OPERATION="$1"
BRANCH_NAME="$2"
valid_name  

if [[ "$BRANCH_OPERATION" =~ ^-(a|\-all)$ ]]; then
    git branch --all -vv
elif [ ! "$BRANCH_NAME" ]; then
    Usage > /dev/stderr
else
    execute_branch_task
fi

