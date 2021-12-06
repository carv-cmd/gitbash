#!/bin/bash

# The stupid git branch manager

PROGNAME="${0##*/}"

if ! ON_BRANCH="$(git branch --show-current)"; then
    exit 1
elif [[ "$1" =~ ^-(a|\-all)$ ]]; then
    git branch --all -vv; exit
fi

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

ORIGIN=${ORIGIN:-origin}
BRANCH_TASK="$1"
BRANCH_NAME="$2"
OK_RESET='b'


Usage () {
    cat >&2 <<- EOF
The stupid git branch manager
usage: 
 $PROGNAME [ -a | --all ]
 $PROGNAME [ -l | --local ] | [ -r | --remote ] BRANCH_NAME
 $PROGNAME [ -m | --merge ] | [ -M ] BRANCH_NAME
 $PROGNAME [ -d | --delete ] | [ -D ] BRANCH_NAME

Options:
 -a, --all          Print all local and remote branches for PWD.
 -l, --local        Checkout BRANCH_NAME from current branch.
 -L                 Force reset/checkout existing BRANCH_NAME.
 -r, --remote       Run [ --local ] and attempt to push BRANCH_NAME upstream.
 -R                 Force reset/checkout of BRANCH_NAME and attempt push upstream.
 -m, --merge        Locally merge BRANCH_NAME into current branch.
 -M                 Run [ --merge ] and attempt to publish changes upstream.
 -d, --delete       Delete LOCAL references to BRANCH_NAME
 -D                 Delete LOCAL and REMOTE references to BRANCH_NAME.
 -h, --help         Display this help message and exit.

=============================================
Environment
============
ORIGIN: 
 Can only be set through environment.
BRANCH: 
 Command line arguments take precedence.
ECHO:
 Set to echo commands instead of executing them.
 ex. \`ECHO=1 $PROGNAME -M BRANCH_NAME\`

EOF
exit 1
}

Error () {
    echo -e "-${PROGNAME%.*}: error: $1\n" > /dev/stderr 
    exit 1
}

make_new_branch () {
    local TRACK=${1:-}
    if ! $sh_c "git checkout -$OK_RESET $BRANCH_NAME $TRACK"; then
        Error "use [ -L | -R ] or [ --help ]"
    fi
}

make_remotes () {
    if make_new_branch '--track'; then
        push_upstream "$BRANCH_NAME"
    fi
}

merge_local () {
    if ! $sh_c "git merge $BRANCH_NAME"; then
        Error 'git merge: failed'
    fi
}

merge_upstream () {
    merge_local
    BRANCH_NAME="$ON_BRANCH" 
    push_upstream
}

remove_locals () {
    if ! $sh_c "git branch -d $BRANCH_NAME"; then
        Error 'remove locals failed'
    fi
}

remove_remotes () {
    check_remote_origin
    remove_locals
    if $sh_c "git branch -d -r $ORIGIN/$BRANCH_NAME"; then
        $sh_c "git push $ORIGIN --delete $BRANCH_NAME"
    fi
}

push_upstream () {
    check_remote_origin
    $sh_c "git push $ORIGIN $BRANCH_NAME"
}

check_remote_origin () {
    if [ -z "$(git remote -v)" ]; then
        Error 'no remote origin'
    fi
}

verbose_branches () {
    git branch --all -vv
}


if [[ "$BRANCH_TASK" =~ ^--?(h(elp)?|a(ll)?)$ ]]; then
    OK_RESET=
elif [[ ! "$BRANCH_NAME" =~ ^[[:alnum:]](\-|\_|\.|[[:alnum:]])*[a-z0-9]$ ]]; then
    Error "invalid_name: [ '$BRANCH_NAME' ]"
fi

case "$BRANCH_TASK" in 
    -a | --all ) verbose_branches;;
    -l | --local ) make_new_branch;;
    -L ) OK_RESET='B' make_new_branch;;
    -r | --remote ) make_remotes;;
    -R ) OK_RESET='B' make_remotes;;
    -m | --merge ) merge_local;;
    -M ) merge_upstream;;
    -d | --delete ) remove_locals;;
    -D ) remove_remotes;;
    -h | --help ) Usage;;
    * ) Error "unknown option: $BRANCH_TASK";;
esac

