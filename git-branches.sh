#!/bin/bash

#        _ _   _                     _    
#   __ _(_) |_| |__ _ _ __ _ _ _  __| |_  
#  / _` | |  _| '_ \ '_/ _` | ' \/ _| ' \ 
#  \__, |_|\__|_.__/_| \__,_|_||_\__|_||_|
#  |___/                                  
#
# git-branches.sh: The stupid git branch manager

SCRUM_MASTER='main'
CW_BRANCH="$(git branch --show-current)"
GIT_ORIGIN=${ORIGIN:-origin}
GIT_BRANCH="${BRANCH:-}"

Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [-b|--branch] [-C|--ctrack] [-D|--delete] NAME
The stupid git branch manager.

Mode Flags:
 -a, --all      Shortcut for \`git branch --all -vv\`
 -b, --branch   Checkout new branch NAME from CW_BRANCH.
 -C, --ctrack   Same as --branch + git push NAME upstream.
 -D, --delete   (CAUTION) Delete all NAME local and remote branches.
 -M, --merge    Merge NAME into current working branch.
 -h, --help     Display this help message and exit.

Environment:

ORIGIN: 
 Used in \`git remote-ops ORIGIN/name\`.
 Can only be set through env variable.

BRANCH: 
 Overrides command line options.
 If set only specify mode flag.

If ref symlinked to another ref such like;
 * remotes/origin/HEAD -> origin/main
 * Use \`git remote set-head origin --delete`\

EOF
exit 1
}

Error () {
    echo -e "\nerror: $1\n" > /dev/stderr 
    exit 1
}

Branch_cleanup () {
    # Delete local branch, remote branch
    if [[ "$GIT_BRANCH" =~ ^$SCRUM_MASTER$ ]]; then
        Error 'protect: main: exiting'
    fi
    $sh_c "git branch -d $GIT_BRANCH" 
    $sh_c "git branch -d -r $GIT_ORIGIN/$GIT_BRANCH"
    $sh_c "git push $GIT_ORIGIN --delete $GIT_BRANCH"
}

Checkouts_tracks () {
    # Checkout $GIT_BRANCH from $CW_BRANCH.
    # If $MODE='ctrack', pos-arg $2 expands to '--track'.
    if $sh_c "git checkout -B $GIT_BRANCH $2"; then
        if [ "$2" ]; then
            $sh_c "git push $GIT_ORIGIN $GIT_BRANCH"
        fi
    fi
}

Branch_merge () {
    if git branch --list | grep -qE "^\* $GIT_BRANCH"; then
        Error "\$GIT_BRANCH( $GIT_BRANCH ) =?= CURRENT( $CW_BRANCH )"
    elif ! git branch --list | grep -q $GIT_BRANCH; then
        Error "$GIT_BRANCH: doesn't exist"
    fi

    if $sh_c "git merge $GIT_BRANCH"; then
        if $sh_c "git push $GIT_ORIGIN $CW_BRANCH"; then
            read -p "Reset: $GIT_BRANCH (y/n)?: "
            [[ "$REPLY" =~ ^(y|yes)$ ]] && Checkout_tracks
        fi
    fi
    exit 
}

Branch_modes () {
    if [[ "$MODE" =~ ^checkout$ ]]; then
        Checkouts_tracks "$TRACKS"
    elif [[ "$MODE" =~ ^ctrack$ ]]; then
        Checkouts_tracks "$TRACKS" '--track'
    elif [[ "$MODE" =~ ^delete$ ]]; then
        Branch_cleanup
    else
        Error "seems fatal"
    fi
}

Set_branch () {
    if [ ! "$1" ]; then
        return 1
    elif [[ "$1" =~ ^-(o|b|C|D|\-origin|\-branch|\-ctrack|\-delete)$ ]]; then
        return 1
    elif [ ! "$BRANCH" ]; then
        if [ ! "$GIT_BRANCH" ]; then
            GIT_BRANCH="$1"
        fi
    fi
}

Parse_args () {
    local iflag=
    while [ -n "$1" ]; do
        iflag="$1"; shift
        case "$iflag" in 
            -a | --all )
                git branch --all -vv; exit
                ;;
            -b | --branch )
                Set_branch "$1" && shift
                ;;
            -C | --ctrack )
                Set_branch "$1" && shift
                MODE='ctrack'
                ;;
            -D | --delete )
                Set_branch "$1" && shift
                MODE='delete'
                ;;
            -M | --merge )
                [[ "$2" =~ ^--dry$ ]] && 
                    sh_c='echo'
                Set_branch "$1" 
                Branch_merge
                ;;
            --dry )
                sh_c='echo'
                ;;
            -h | --help )
                Usage
                ;;
            * ) 
                Error 'invalid argument'
                ;;
        esac
    done

    if [[ "$GIT_BRANCH" =~ ^--dry$ ]]; then
        Error 'NAME !!= --dry'
    elif [ ! "$GIT_BRANCH" ]; then 
        # Defaults to 'develop' branch if no given
        Set_branch 'develop'
    elif [[ ! "$GIT_BRANCH" =~ $BRANCH_REGEX ]]; then
        # Tries to keep branch names manageable
        Error "regex( $BRANCH_REGEX )"
    fi
}


sh_c='sh -c'
MODE='checkout'
BRANCH_REGEX='^([[:alnum:]]|\-|\_|\.)+$'

Parse_args "$@"
Branch_modes $GIT_BRANCH

