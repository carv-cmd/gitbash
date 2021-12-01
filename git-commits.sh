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

Usage () {
	cat <<- EOF
${PROGNAME} - the stupid git commit manager

usage: ${PROGNAME} [ -m ] [ -q ] [ -t ] [ -D ] [ -E ]

Examples:
   ${PROGNAME} [ -q ][ -t ]
   ${PROGNAME} -t -m 'commitMsg'
   ${PROGNAME} -q -t -m 'commitMsg'

Options
 -m, --message      Custom commit message.
 -p, --push         Push upstream after committing changes.
 -q, --quiet        Dont prompt before 'add && commit' (automation).
 -t, --templates    Create README.md & .gitignore files if they dont exist.
 -D, --dry-run      Execute git commands with --dry-run flags
 -E, --echo         Echo commands that will be executed(debug).
 -h, --help	    Display this prompt and exit.

EOF
exit 1
}

Error () {
    echo -e "error: $1"
    exit 1
}

Commit_msg () {
    local short_stat="$(git status --short)"
    if [[ "$STATUS" =~ ^null$ ]]; then
        echo "$short_stat" 
    else
        echo -e "\nPreAdd:\n${STATUS}\nPostCommit:\n$short_stat\n"
    fi
}

Update_index () {
    [ -n "$COMMIT_MSG" ] && return
    git status --short
    local REPLY=yes

    if [ -z "${KWARGS["quiet"]}" ]; then
        read -p '[ add && commit ](y/n)?: '
    fi
    case "$REPLY" in
        y | yes )  $sh_c "git add $DRY_RUN ." || Error 'git add';;
        * )  Error 'git add';;
    esac
}

Template_files () {
    local CWD=$(pwd)
    if [ ! -f ./README.md ]; then
        $sh_c "set -C; echo '# ${CWD##*/}' > ./README.md"
    fi
    if [[ -e "$GIT_IGNORE" && ! -e ./.gitignore ]]; then
        $sh_c "cp $GIT_IGNORE .gitignore"
    fi
}

Main_loop () {
    STATUS=
    if [[ -z "$COMMIT_MSG" ]];then
        readarray -d '\n' STATUS < <(git status --short || false) 
        [ ! "$STATUS" ] && STATUS='null'
    fi

    [ -n "${KWARGS["templates"]}" ] && Template_files
    Update_index

    COMMIT_MSG="$(Commit_msg $STATUS)"
    $sh_c "git commit $DRY_RUN -m '${COMMIT_MSG}'"
    if [ -n "${KWARGS["push"]}" ]; then
        $sh_c "git push $DRY_RUN origin $(git branch --show-current)"
    fi
}

Parse_args () {
    COMMIT_MSG=
    while [ -n "$1" ]; do
        case "$1" in
            -m | --message )  shift; COMMIT_MSG="$1";;
            -p | --push )  KWARGS['push']='p';;
            -q | --quiet )  KWARGS["quiet"]='q';;
            -t | --templates )  KWARGS['templates']='t';;
            -D | --dry-run ) DRY_RUN='--dry-run';;
            -E | --echo ) sh_c='echo';;
            -h | --help )  Usage;;
            * )  Error 'unknown token';;
        esac
        shift
    done
}


if [ ! -d "$(pwd)/.git" ]; then
    git status
    exit
fi

sh_c='sh -c'
declare -A KWARGS
Parse_args "${@}"
Main_loop

