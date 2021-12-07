#!/bin/bash

# Manage upstream GitHub repositories.
VERSION='1.10'
GITBASH=~/bin/gitbash

#sh_c='sh -c'
sh_c='echo'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='sh -c'

VISIBILITY=${VISIBILITY:-private}
LOCAL_GITS=${LOCAL_GITS:-$HOME/git-repos}
GIT_IGNORE=$GITBASH/template.gitignore


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [ --query ] | [ --default ] REPO_NAME

Options:
 -d, --default      Creates directory in \$LOCAL_GITS: $LOCAL_GITS, else use \$PWD.
 -p, --public       Set upstream repository visibility. default=private.
 -h, --help         Display this help message and exit.

Environment
============
LOCAL_GITS:
 Use --default flag create repos in \$LOCAL_GITS.
 \$LOCAL_GITS=$LOCAL_GITS

VISIBILITY:
 Command line arguments take precedence.
 Visibility defaults to private.

EOF
exit
}

Error () {
    echo -e "$1\n" > /dev/stderr
    exit 1
}

parse_args () {    
    for arg in $@; do
        case "$arg" in 
            -d | --default ) use_default;;
            -p | --visibiltiy ) VISIBILITY=private;;
            -h | --help ) Usage;;
            -* | --* ) Usage;;
            * ) REPO_NAME="$arg";;
        esac
    done
}

use_default () {
    if [ "$LOCAL_GITS" -a ! -d "$LOCAL_GITS" ]; then
        make_default
    fi
    cd $LOCAL_GITS
}

make_default () {
    if [ ! -d "$LOCAL_GITS" ]; then
        $sh_c "mkdir $LOCAL_GITS" || Error 'no default'
    fi
}

make_local_repository () {
    if [ ! -d "$REPO_NAME/.git" ]; then
        $sh_c "git init $REPO_NAME"
    fi
}

checkout_main () {
    if [[ ! "$(git branch --show-current)" =~ ^main$ ]]; then
        $sh_c 'git checkout -B main'
    fi
}

make_readme () {
    if [ ! -f ./READNE.md ]; then
        $sh_c "echo '# ${PWD##*/}' > ./README.md"
    fi
}

cp_gitignore () {
    if [[ -e "$GIT_IGNORE" && ! -f .gitignore ]]; then
        $sh_c "cp $GIT_IGNORE ./.gitignore"
    fi
}

commit_local_state () {
    $sh_c "git add ."
    $sh_c "git commit -m '$(git status --short)'"
}

create_upstream () {
    if ! $sh_c "gh repo create $REPO_NAME --$VISIBILITY --source=."; then
        Error 'create upstream failed'
    fi
}

push_upstream () {
    if ! $sh_c "git push --set-upstream origin main"; then
        Error 'push_upstream failed'
    fi
}

prepare_repository () {
    checkout_main
    make_readme
    cp_gitignore
    commit_local_state
}

REPO_NAME=
parse_args "$@"

TEST_NAME='^[[:alnum:]](\-|\_|\.|[[:alnum:]])*[[:alnum:]]$'
if [ ! "$REPO_NAME" ]; then
    Usage
elif [[ ! "$REPO_NAME" =~ $TEST_NAME ]]; then
    Error "regex-failed: $REPO_NAME"
fi

make_local_repository 
if ! cd $REPO_NAME; then
    Error "can't \`cd\` into $REPO_NAME"
fi
prepare_repository
create_upstream
push_upstream

