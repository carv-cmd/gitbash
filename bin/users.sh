#/bin/bash

sh_c='echo'
# sh_c='sh -c'
ECHO=${ECHO:-}
[ "$ECHO" ] && sh_c='echo'


Usage () {
    PROGNAME="${0##*/}"
    cat <<- EOF
The stupid git user manager

usage: 
  $PROGNAME [--name <name>][--email <gh_email>]
  $PROGNAME [--colors][--keygen <email>][--token <gh_token>]

Flags:
 -c, --colors       Global autocoloring for logs, diff, etc
 -e, --editor       Set the editor git will use, default=vim
 -E, --email        Email address associated with GitHub.com
 -N, --name         Username associated with GitHub.com
 -K, --keygen	    Generate id_25519 ssh key for git-over-ssh.
 -T, --token        Add token generated for 'gh auth login'(https)
 -h, --help         Display this help message and exit

EOF
exit 1
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    exit 1
}

parse_args () {
    ARG=
    while [ -n "$1" ]; do
        ARG="$1"; shift
        case "$ARG" in
            -c | --colors ) COLORS=1; continue;;
            -e | --editor ) EDITOR="$1";;
            -E | --email ) GITMAIL="$1";;
            -N | --name ) GITNAME="$1";;
            -K | --keygen ) GEN_SSH_KEY=1; continue;;
            -T | --token ) ADD_TOKEN="$1";;
            -* | --* )  Usage;;
            * )  Error "argument: $1";;
        esac
        shift
    done
}

set_git_configs () {
    local KEY="$1"
    local VALUE="$1"
    local CHK_CONFIG="$(git config --global --get $1)"
    if [[ ! "$CHK_CONFIG" ]]; then
        $sh_c "git config --global '$KEY' '$VALUE'"
    else
        echo "'$KEY=$CHK_CONFIG' <-x- $VALUE"
    fi
}

auto_colors () {
    if [ "$AUTO_COLORS" ]; then
        BASE_COL=('status' 'branch' 'interactive' 'diff')
        for SET_COL in "${BASE_COL[@]}"; do 
            Set_git_config "color.$SET_COL" 'auto'
        done
    fi
}

set_text_editor () {
    if [ "$EDITOR" ]; then
        Set_git_config 'core.editor' 'vim'
    fi
}

set_user_name () {
    if [ "$GITNAME" ]; then
        Set_git_config 'user.name' "$1"
    fi
}

set_email () {
    if [[ "$GITMAIL" =~ ^([[:alnum:]]|\.|\_|\-)+@([[:alnum:]]|\.)+\.[a-z]{2,5}$ ]]; then
        set_git_config 'user.email' "$GITMAIL"
    fi
}

make_ssh_key () {
    GH_KEY_PAIR=~/.ssh/id_ed25519
    [ -r "$GH_KEY_PAIR.pub" ] && Error "found: $GH_KEY_PAIR"
    
    ssh_key_comment
    if ssh-keygen -o -t ed25519 -C $USER_EMAIL; then
        cat "${KEY_NAME}.pub"
    fi
}

ssh_key_comment () {
    USER_EMAIL="$(git config --global --get user.email)"
    [ "$GEN_SSH_KEY" ] && USER_EMAIL="$GEN_SSH_KEY"
    if [[ ! "$USER_EMAIL" ]]; then
        Error '--keygen requires an email for comment'
    fi
}

bashrc_append_token () {
    if grep 'GH_TOKEN' ~/.bashrc; then
        Error 'found token in ~/.bashrc'
    elif [ -n "$ADD_TOKEN" ]; then
        token_string >> ~/.bashrc
        source ~/.bashrc
        unset 'ADD_TOKEN'
    fi
}

token_string () {
    cat <<- EOF
# Added on: $(date +%D)
export GH_TOKEN='$ADD_TOKEN'
EOF
}

####
[[ ! "$@" ]] && Usage
parse_args "$@"
auto_colors
set_text_editor
set_user_name
set_email

# Generate SSH id_ed25519 public/private key pair
make_ssh_key

# Add `export GH_TOKEN=...` to $USER/.bashrc
bashrc_append_token

