#!/bin/bash


# git-branches.sh: The stupid git branch manager

Chkout_dev_set_upstream () {
	# Checkout development branch from main branch.
	local CURRENT_BRANCH="$(git branch --show-current)"

	if [[ "${CURRENT_BRANCH}" == main ]]; then
		git checkout -b develop
		git push --set-upstream origin develop
	fi
}

Chkout_dev_set_upstream

