#!/bin/bash


FLAG="$1"; shift
ARG="$@"


Usage () {
    PROGNAME="${0##*/}"
    cat >&2 <<- EOF
Shortcuts for: 
 \`gh repo list [ FLAG [ PARAM ]]\`
 \`gh api graphql ...\`

usage: gitman ${PROGNAME%.*} [ FLAG [ PARAM ]]

$(gh repo list --help | grep -C 12 ^FLAGS$ | tail -n +8)
      --graphql           List all owned Github repositories in JSON format.
  -h, --help              Display this help message and exit.

EOF
exit 1
}

Error () {
    echo -e "error: $1\n" > /dev/stderr
    Usage
}

graphql_query () {
    gh api graphql --paginate --cache '15s' -f query="$(query_string)"
}

graphql_query_string () {
    cat <<- 'EOF'
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
EOF
}

gh_cli_query () {
    if ! gh repo list $FLAG $ARG 2> /dev/null; then
        Error "invalid input: $FLAG: $ARG"
    fi
}


if [ ! "$FLAG" ]; then
    gh_cli_query
elif [[ "$FLAG" =~ ^--?h(elp)?$ ]]; then
    Usage
elif [[ "$FLAG" =~ ^--graphql$ ]]; then
    graphql_query
else
    gh_cli_query "$FLAG" "$ARG"
fi

