#!/bin/bash

# install-gh-cli.sh: Self explanatory

Cmd_exists () {
	command -v "$@" > /dev/null 2>&1
}

Prog_error () {
	echo "$1"
	exit 1
}

Install_gh () {
	# Get GH pulic gpg key and add it to machines keyring
	GPG_URL='https://cli.github.com/packages/githubcli-archive-keyring.gpg'
	KEY_RINGS='/usr/share/keyrings/githubcli-archive-keyring.gpg'

	# Build source.list entry and add source into listings
	SRC_INTO='/etc/apt/sources.list.d/github-cli.list'
	SRC_URL='https://cli.github.com/packages stable main'
	ADD_SRC="deb [arch=$(dpkg --print-architecture) signed-by=${KEY_RINGS}] $SRC_URL"
	
	if [ ! -e "${KEY_RINGS}" ]; then
		curl -fsSL $GPG_URL | sudo gpg --dearmor -o $KEY_RINGS || 
			Prog_error 'no key grab'
	fi

	if [ ! -e "${SRC_INTO}" ]; then 
		echo "$ADD_SRC" | sudo tee "$SRC_INTO" > /dev/null || 
			Prog_error 'no source'
	fi

	if ! Cmd_exists gh; then
		sudo apt update && sudo apt install gh 
	else
		Prog_error 'gh already exists on host'
	fi
}

Install_gh

