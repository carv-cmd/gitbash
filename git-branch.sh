#!/bin/bash

#       _ _   _                  
#  __ _(_) |_| |__ _ _ __ _ _ _  
# / _` | |  _| '_ \ '_/ _` | ' \ 
# \__, |_|\__|_.__/_| \__,_|_||_|
# |___/                          
# 
# The stupid git branch manager

if ! ON_BRANCH="$(git branch --show-current)"; then
    exit 1
elif [[ "$1" =~ ^-(a|\-all)$ ]]; then
    git branch --all -vv; exit
fi

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

MASTER='main'
ORIGIN=${ORIGIN:-origin}
BRANCH_TASK="$1"
BRANCH_NAME="$2"


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME

 $PROGNAME [-a|--all]
 $PROGNAME [-m|--merge] BRANCH_NAME
 $PROGNAME [-l|--mk-locals]|[-L|--rm-locals] BRANCH_NAME
 $PROGNAME [-r|--mk-remotes]|[-R|--rm-remotes] BRANCH_NAME

Options:
 -l, --mk-locals        Checkout new BRANCH_NAME from ON_BRANCH.
 -r, --mk-remotes       Identical to -l, but pushes BRANCH_NAME upstream.
 -m, --merge            Merge BRANCH_NAME into ON_BRANCH.
 -L, --rm-locals        Delete local references to BRANCH_NAME
 -R, --rm-remotes       Delete remote reference to BRANCH_NAME.
 -a, --all              Print \`git branch --all -vv\` and exit.
 -h, --help             Display this help message and exit.

=============================================
Environment
============
ORIGIN: 
 Can only be set through environment.
BRANCH: 
 Command line arguments take precedence.
ECHO:
 Set true to echo cmds instead of executing them.
 ex. \`ECHO=true $PROGNAME -mk-remotes BRANCH_NAME\`

EOF
exit
}

Error () {
    echo -e "error: $1\n" > /dev/stderr 
    exit 1
}

execute_branch_task () {
    case "$BRANCH_TASK" in 
        -l | --mk-locals )  make_locals;;
        -r | --mk-remotes ) make_remotes;; 
        -m | --merge )  merge_branches;;
        -L | --rm-locals ) remove_locals;;
        -R | --rm-remotes )  remove_remotes;;
        -h | --help )  Usage;;
        * ) Error "unknown option: $BRANCH_TASK"
    esac
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
        $sh_c "git push $ORIGIN $ON_BRANCH"
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

if [ ! "$BRANCH_NAME" ]; then
    Usage > /dev/stderr
elif [[ ! "$BRANCH_NAME" =~ ^[[:alnum:]](\-|\_|\.|[[:alnum:]])*[a-z0-9]$ ]]; then
    Error "invalid branch_name: $BRANCH_NAME"
fi

execute_branch_task

