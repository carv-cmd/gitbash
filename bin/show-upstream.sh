#!/bin/bash

#      _                                _                      
#   __| |_  _____ __ _____ _  _ _ __ __| |_ _ _ ___ __ _ _ __  
#  (_-< ' \/ _ \ V  V /___| || | '_ (_-<  _| '_/ -_) _` | '  \ 
#  /__/_||_\___/\_/\_/     \_,_| .__/__/\__|_| \___\__,_|_|_|_|
#                              |_|                             
#
# Print all upstream repositories owned by $(git config --get user.name)

query_string () {
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

# GH API graphql query. See gh docs for details.
gh api graphql --paginate --cache '15s' -f query="$(query_string)"

