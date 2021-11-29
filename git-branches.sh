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
GIT_ORIGIN="${ORIGIN:-origin}"
GIT_BRANCH="${BRANCH:-}"

Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME [-b|--branch] [-C|--ctrack] [-D|--delete] NAME
The stupid git branch manager.

Mode Flags:
 -b, --branch   Checkout new branch NAME from CW_BRANCH.
 -C, --ctrack   Same as --branch + git push NAME upstream.
 -D, --delete   (CAUTION) Delete all NAME local and remote branches.
 -M, --merge    Merge NAME into current working branch.

Environment:

ORIGIN: 
 Used in \`git remote-ops ORIGIN/name\`.
 Can only be set through env variable.

BRANCH: 
 Overrides command line options.
 If set only specify mode flag.

EOF
exit 1
}

Error () {
    echo -e "\nerror: $1\n" > /dev/stderr 
    exit 1
}

Cleanup_branches () {
    # Delete local branch, remote branch
    if [[ "$GIT_BRANCH" =~ ^$SCRUM_MASTER$ ]]; then
        Error 'protect: main: exiting'
    fi
    $sh_c "git branch -d $GIT_BRANCH" && 
        $sh_c "git branch -d -r $GIT_ORIGIN $GIT_BRANCH" && 
        $sh_c "git push $GIT_ORIGIN --delete $GIT_BRANCH"
}

Checkouts_tracks () {
    # Checkout $GIT_BRANCH from $CW_BRANCH.
    # If $MODE='ctrack', pos-arg $2 expands to '--track'.
    if $sh_c "git checkout -b $GIT_BRANCH $2"; then
        if [ "$TRACKS" ]; then
            $sh_c "git push $GIT_ORIGIN $GIT_BRANCH"
        fi
    fi
}

Branch_modes () {
    # BranchModes: [checkout-local, >& track, delete]
    if [[ "$MODE" =~ ^checkout$ ]]; then
        Checkouts_tracks "$TRACKS"
    elif [[ "$MODE" =~ ^ctrack$ ]]; then
        Checkouts_tracks "$TRACKS" '--track'
    elif [[ "$MODE" =~ ^delete$ ]]; then
        Cleanup_branches
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

Branch_merge () {
    if git branch --list | grep -qE "^\* $GIT_BRANCH"; then
        Error "\$GIT_BRANCH( $GIT_BRANCH ) =?= CURRENT( $CW_BRANCH )"
    elif ! git branch --list | grep -q $GIT_BRANCH; then
        Error "$GIT_BRANCH: doesn't exist"
    fi

    $sh_c "git merge $GIT_BRANCH"
    read -p "Purge: $GIT_BRANCH (y/n)?: "
    if [[ "$REPLY" =~ ^(y|yes)$ ]]; then
        Cleanup_branches
    fi
    exit 
}

Parse_args () {
    local iflag=
    while [ -n "$1" ]; do
        iflag="$1"; shift
        case "$iflag" in 
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
                Set_branch "$1" 
                Branch_merge
                ;;
            --dry )
                sh_c='echo'
                ;;
            * ) 
                Error 'invalid argument'
                ;;
        esac
    done

    if [[ "$GIT_BRANCH" =~ ^--dry$ ]]; then
        Error 'NAME !!= --dry'
    elif [[ ! "$GIT_BRANCH" =~ $BRANCH_REGEX ]]; then
        # Tries to keep branch names manageable
        Error "regex( $BRANCH_REGEX )"
    elif [ ! "$GIT_BRANCH" ]; then 
        # Defaults to 'develop' branch if no given
        Set_branch 'develop'
    fi
}


sh_c='echo' #<- sh -c'
MODE='checkout'
BRANCH_REGEX='^([[:alnum:]]|\-|\_|\.)+$'

Parse_args "$@"
Branch_modes $GIT_BRANCH

