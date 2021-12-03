#!/bin/bash

#       _ _                        
#  __ _(_) |_ _ _ ___ _ __  ___ ___
# / _` | |  _| '_/ -_) '_ \/ _ (_-<
# \__, |_|\__|_| \___| .__/\___/__/
# |___/              |_|           
# 
# Manage upstream GitHub repositories.
VERSION='1.01'

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'

LOCAL_GITS=${LOCAL_GITS:-$HOME/git-repos}

GITBASH="$HOME/bin/gitbash"
GIT_IGNORE="$GITBASH/template.gitignore"


query_remotes () {
    # GH API graphql query. See gh docs for details.
    gh api graphql --paginate --cache '15s' -f query='
    query($endCursor: String) {
      viewer {
        repositories(first: 100, after: $endCursor) {
          nodes { nameWithOwner }
          pageInfo {
            hasNextPage
               endCursor
          }
        }
      }
    }
    '
}

if [[ "$1" =~ ^-(q|\-query-remotes)$ ]]; then
    query_remotes
    exit
fi


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [ --query ] | [ --default ] REPO_NAME

Options:
 -d, --default      Creates directory in \$LOCAL_GITS: $LOCAL_GITS, else use \$PWD.
 -q, --query        Get all GitHub.com remote repositories owned by user.
 -p, --public       Set repo pubic when pushing upstream. default=private.
 -h, --help         Display this help message and exit.

Environment
============
LOCAL_GITS:
 Default directory to create git repos in. 
 Current default is: $LOCAL_GITS

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
        checkout_main
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

copy_gitignore () {
    if [[ -e "$GIT_IGNORE" && ! -f .gitignore ]]; then
        $sh_c "cp $GIT_IGNORE ./.gitignore"
    fi
}

commit_local_state () {
    checkout_main
    $sh_c "git add ."
    $sh_c "git commit -m '$(git status --short)'"
}

send_upstream () {  
    if $sh_c "gh repo create --$VISIBILITY --confirm $REPO_NAME"; then
        $sh_c "git push --set-upstream origin $(git branch --show-current)"
    else
        Error 'create upstream failed'
    fi
}


REPO_NAME=
TEMPLATES=
parse_args "$@"

TEST_NAME='^[[:alnum:]](\-|\_|\.|[[:alnum:]])*[[:alnum:]]$'
if [ ! "$REPO_NAME" ]; then
    Usage
elif [[ ! "$REPO_NAME" =~ $TEST_NAME ]]; then
    Error "regex failed: $REPO_NAME"
fi

make_local_repository 
if cd $REPO_NAME; then
    make_readme
    copy_gitignore
    commit_local_state
    checkout_main
    send_upstream
else
    Error "cant access $REPO_NAME"
fi

