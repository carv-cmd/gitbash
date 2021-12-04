#!/bin/bash

#       _ _                
#  __ _(_) |_ __ ___ _ __  
# / _` | |  _/ _/ _ \ '  \ 
# \__, |_|\__\__\___/_|_|_|
# |___/                    
# 
# gitcom: Quick and simple `git (add|commit)` manager

PROGNAME=${0##*/}
GITBASH="${HOME}/bin/gitbash"
GIT_IGNORE="${GITBASH}/template.gitignore"

sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'


Usage () {
	cat <<- EOF
usage: $PROGNAME [ -d ][ -q ][ -p ][ -m 'A custom commit msg' ]

The stupid git commit manager

Options
 -d, --dry-run      Execute git commands with --dry-run flag.
 -m, --message      Pass custom commit message, else use \`git status --short\`.
 -p, --push         Push changes upstream after committing them.
 -q, --quiet        Dont prompt before 'add && commit' (scripts).
 -h, --help	    Display this prompt and exit.

EOF
exit 
}

Error () {
    echo -e "error: $1" > /dev/stderr
    exit 1
}

parse_args () {
    while [ -n "$1" ]; do
        case "$1" in
            -d | --dry-run ) DRY_RUN='--dry-run';;
            -m | --message )  shift; COMMIT_MSG="$1";;
            -p | --push )  PUSH=1;;
            -q | --quiet )  QUIET=1;;
            -h | --help )  Usage;;
            * ) ;;
        esac
        shift
    done
}

prompt_user () {
    git status --short
    read -p '[ add && commit ](y/n)?: '
    if [[ ! "$REPLY" =~ ^y(es)?$ ]]; then
        Error 'user opted-out'
    fi
}

update_git_index () {
    if ! $sh_c "git add $DRY_RUN ."; then
        Error 'git add: failed'
    fi
}

set_commit_msg () {
    if [ -z "$COMMIT_MSG" ]; then
        COMMIT_MSG="ChangeLog:\n$(git status --short)\n"
    fi
    echo -e "$COMMIT_MSG"
}

commit_changes () {
    if ! $sh_c "git commit $DRY_RUN -m '$(set_commit_msg)'"; then
        Error 'git commit failed'
    fi
}

push_upstream () {
    if ! $sh_c "git push $DRY_RUN origin $(git branch --show-current)"; then
        Error 'push upstream failed'
    fi
}


if [ ! -d $PWD/.git ]; then
    git status
    exit
fi

COMMIT_MSG= 
parse_args "${@}"

[ ! "$QUIET" ] && prompt_user

update_git_index
commit_changes

if [ "$PUSH" ]; then
    push_upstream
fi

