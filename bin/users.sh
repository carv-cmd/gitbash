#/bin/bash

# Configure Git --global's for user account (Ubuntu).
# Default editor is set as Vim, branch name is 'main' to mirror GitHub default.
# Username has no filter, email regex filters only alnum & ( ., -, _, @ ).
# SSH --keygen uses email associated with user in ~/.gitconfig.

PROGNAME="${0##*/}"

Usage () {
    cat <<- EOF
$PROGNAME: the stupid git repo manager

usage: 
  $PROGNAME --user-info <name> <gh_email> 
  $PROGNAME [ --basic ] [ --keygen ] [ --token <gh_token> ]

Flags:
 -b, --basic	    Set: autocolor, editor=vim, default_branch_name=main.
 -k, --keygen	    Generate id_25519 ssh key for git-over-ssh.
 -t, --token        Add token generated for 'gh auth login'.
 -u, --user-info    Set Git username and email for $USER.
 -h, --help         Display this help message and exit.

EOF
exit 1
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    exit 1
}

Add_ssh_key () {
    local KEY_NAME="$HOME/.ssh/id_ed25519"
    [ -r "${KEY_NAME}.pub" ] && 
        Error "$KEY_NAME: exists"

    USER_EMAIL="$(git config --global --get user.email)"
    if [[ ! "${USER_EMAIL}" ]]; then
        Error '--keygen require user.email to be set'
    fi

    ssh-keygen -o -t ed25519 -C $USER_EMAIL && cat "${KEY_NAME}.pub"
}

Add_gh_token () {
    if [[ "$(grep 'GH_TOKEN' "${HOME}/.bashrc")" ]]; then
        Error 'found token in ~/.bashrc'
    fi

    if [ -n "${ADD_TOKEN}" ]; then
        echo "# Added: $(date +%D)" >> "${HOME}/.bashrc"
        echo "export GH_TOKEN='${ADD_TOKEN}'" >> "${HOME}/.bashrc"
        source "${HOME}/.bashrc"
    fi
    unset 'ADD_TOKEN'
}

Set_git_config () {
    local CHK_CONFIG="$(git config --global --get ${1})"
    if [[ ! "$CHK_CONFIG"  ]]; then
        git config --global "$1" "$2" || Prog_error '003'
    else
        Error "fatal: '$1 $CHK_CONFIG' <- $2"
    fi
}

Set_basic () {
    # Default branch name Git gives forks.
    Set_git_config 'init.defaultBranch' 'main'
    # Set the default editor Git uses; default is Vim.
    Set_git_config 'core.editor' 'vim'

    # Set colors: color.(status|branch|interactive|diff)=auto
    BASE_COL=('status' 'branch' 'interactive' 'diff')
    for SET_COL in "${BASE_COL[@]}"; do 
        Set_git_config "color.$SET_COL" 'auto'
    done
    }

Set_user_info () {
    # Set Git $1:username and $2:email.
    if [[ "$1" && "$2" ]]; then
        if [[ "$2" =~ ^([[:alnum:]]|\.|\_|\-)+@([[:alnum:]]|\.)+\.[a-z]{2,5}$ ]]; then
            Set_git_config 'user.name' "$1"
            Set_git_config 'user.email' "$2"
        else
            Error 'user.email conflict'
        fi
    else
        Error 'user.name conflict'
    fi
}

Main_loop () {
    while [ -n "$1" ]; do
        case "$1" in
            -b | --basic )  Set_basic;;
            -u | --user-info )  shift; Set_user_info "$1" "$2"; shift;;
            -k | --keygen )  GEN_SSH_KEY=1;;
            -t | --token )  shift; ADD_TOKEN="$1";;
            -h | --help )  Usage;;
            -* | --* )  Error "argument: $1";;
            * )  Error "argument: $1";;
        esac
        shift
    done
    # Generate SSH id_ed25519 public/private key pair
    [[ "$GEN_SSH_KEY" ]] && Add_ssh_key

    # Add `export GH_TOKEN=...` to $USER/.bashrc
    [[ "$ADD_TOKEN" ]] && Add_gh_token "$ADD_TOKEN"
}


if [[ ! "${@}" ]]; then
    Usage
fi
Main_loop "$@"

