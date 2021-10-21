#!/bin/bash


# git-branches.sh: The stupid git branch manager

Checkout_dev () {
	git branch 
}

cat <<- EOF

Listing git branches:
$(git branch --list -r)

EOF

