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

Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git commit manager

usage: ${PROGNAME} [ -m ] [ -q ] [ -t ]

Examples:
   ${PROGNAME} [ -q ][ -t ]
   ${PROGNAME} -t -m 'commitMsg'
   ${PROGNAME} -q -t -m 'commitMsg'

Options
 -h, --help	    Display this prompt and exit.
 -m, --message      Custom commit message.
 -p, --push         Push upstream after committing changes.
 -q, --quiet        Dont prompt before 'add -> commit'.
 -t, --templates    Create README.md & .gitignore files if doesn't exist.

EOF
exit 1
}

Error () {
    declare -A ERR
    ERR['token']='unknown parameter'
    ERR['noAdd']='`git add` failed'
    ERR['noGit']='./.git does not exist in directory'
    ERR['noCom']='failed commit'
    ERR['push']='git push upstream failed'
    echo -e "\nraised: ${ERR[${1}]}"
    unset 'ERR'
    exit 1
}

Template_files () {
    local CWD=$(pwd)
    local MK_README="${CWD}/README.md"
    local GITIGNORE="${CWD}/.gitignore"
    local TEMPLATE="${GITBASH}/template.gitignore"

    if [ ! -f "$MK_README" ]; then
        echo "# ${CWD##*/}" >> "$MK_README"
    fi
    if [[ -e "$TEMPLATE" && ! -e "$GITIGNORE" ]]; then
        cp "$GITIGNORE" .gitignore
    fi
}

Select_add () {
    # Yes `git commit --interactive` exists, I dont like it.
    cat <<- 'EOF'
 * Enter filenames to `git add` from listing above.
 * One or more filenames can be passed on each line entry.
 * Pass string 'exit' to exit without making any changes.
 * Add & Commit changes with 2 blank newlines.
 * Staged command printed for confirmation before execution.
 * Duplicates are ignored; i.e. `git add x.py x.py` == `git add x.py`
EOF
    declare -a _ADDER
    while true; do
        read -a REPLY -rep "Queue:[ ${_ADDER[@]}]<<< "
        
        if [[ "${REPLY}" == 'exit' ]]; then
            Error 'noAdd'

        elif [[ ! "${REPLY}" ]]; then
            echo; read -p "git add ${_ADDER[@]} <<<(y/n): "
            [[ "${REPLY}" =~ ^(y|yes)$ ]] && break

        else
            printf '\033[0F\033[0J'
            for _valid in "${REPLY[@]}"; do
                if [ ! -e "$_valid" ]; then
                    echo -e "FilenameError: '${_valid}'\n"
                else
                    _ADDER+="$_valid"
                fi
            done
    fi

    done
    if (( ${#_ADDER} )); then 
        git add ${_ADDER[@]}
    else
        Error 'noAdd'
    fi
}

Prompt_user () {
    git status --short; echo
    read -p '[ add && commit ]:(y/n/[s]elect): '
    case "$REPLY" in
        y | yes )  git add . || Error 'noAdd';;
        s | select )  Select_add || Error 'noAdd';;
        * )  Error 'noAdd';;
    esac
}

Commit_msg () {
    if [[ -n "${_SETUP['message']}" ]];then
        echo "${_SETUP['message']}"
    elif [[ "${STATUS}" ]]; then	
        echo -e "\nPreAdd:\n$STATUS\nPostCommit:\n$(git status --short)\n"
    elif [[ ! "${STATUS}" == 'null' ]]; then
        echo "$(git status --short)" 
    fi
}

Main_loop () {
    local STATUS=
    readarray -d '\n' STATUS < <(git status --short || false) 
    [ -z "$STATUS" ] && STATUS='null'

    (( ${_SETUP['templates']} )) && Template_files  
    (( ${_SETUP['quiet']} )) && git add . || Prompt_user
    git commit -m "$(Commit_msg)" 
}

Parse_args () {
    declare -A _SETUP
    while [ -n "$1" ]; do
        case "$1" in
            -m | --message )  shift; _SETUP['message']="$1";;
            -p | --push )  _SETUP['push']=1;;
            -q | --quiet )  _SETUP['quiet']=1;;
            -t | --templates )  _SETUP['templates']=1;;
            -h | --help )  Usage;;
            * )  Error 'token';;
        esac
        shift
    done
    Main_loop "$_SEUTP"

    if (( ${_SETUP['push']} )); then 
        git push origin $(git branch --show-current) || Error 'push'
    fi
}

[ -e "$(pwd)/.git" ] || Error 'noGit'
Parse_args "${@}"

