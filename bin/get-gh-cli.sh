#!/bin/bash

# GH pulic GPG key, this is added to your machines keyring.
GH_GPG_URL='https://cli.github.com/packages/githubcli-archive-keyring.gpg'
GH_GPG_KEY='/usr/share/keyrings/githubcli-archive-keyring.gpg'

# GH upstream source URL.
SRC_URL='https://cli.github.com/packages stable main'

# Build source.list entry.
ADD_SRC="deb [arch=$(dpkg --print-architecture) signed-by=${GH_GPG_KEY}] $SRC_URL"

# Saves $ADD_SRC here.
UPSTREAM_REF='/etc/apt/sources.list.d/github-cli.list'


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
usage: $PROGNAME --run

Install the GitHub command line client (gh-cli).
If \`gh\` found locally, update instead.

Options:
 --run      Execute commands (w/ sudo). default=echo

EOF
exit
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    exit 1
}

get_gpg_key () {
    if ! $sh_c "curl -fsSL $GH_GPG_URL | gpg --dearmor -o $GH_GPG_KEY"; then
        Error 'key grab failed'
    fi
}

add_gh_upstream_source () {
    if $sh_c "echo '$ADD_SRC' | tee $UPSTREAM_REF > /dev/null"; then
        Error 'no gh upstream source'
    fi
}

sh_c='echo'
if [[ "$1" =~ ^--?h(elp)?$ ]]; then
    Usage
elif [[ "$1" =~ ^--run$ ]]; then
    echo "sh_c='sudo -E sh -c'"
fi

[ ! -e "$GH_GPG_KEY" ] && get_gpg_key
[ ! -f "$UPSTREAM_REF" ] && add_gh_upstream_source
$sh_c 'apt-get update -y && apt-get upgrade' && 
    $sh_c 'apt-get install gh'

