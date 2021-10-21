#!/bin/bash

# gitcom: Quick and simple `git (add|commit)` manager


PROGNAME="${0##*/}"
_GITBASH="${0%/*}/gitbash"


Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git commit manager

usage: ${PROGNAME} [ -m ] [ -q ] [ -t ]

Examples:
   ${PROGNAME} -q -t 'main' -m 'commitMsg'
   ${PROGNAME} -t -m 'commitMsg'
   ${PROGNAME} -q

 Flags:
   -m | --cmsg		= commit message (git commit -m '')
   -q | --quiet		= dont prompt before 'add -> commit' (use wisely)
   -t | --templates	= generate README.md & .gitignore files if ! exist

EOF
exit 1
}

Prog_error () {
	declare -A ERR
	ERR['token']='unknown parameter'
	ERR['noAdd']='`git add` failed'
	ERR['noGit']='.git ! exist in directory'
	echo -e "\nraised: ${ERR[${1}]}"
	unset 'ERR'
	exit 1
}

Template_files () {
	# Generate basic 'README.md' and '.gitignore' files if they dont exist.

	local _CWD="$(pwd)"
	local _README="${_CWD}/README.md"
	local _IGNORE="${_CWD}/.gitignore"
	local _GITIGNORE="${_GITBASH}/template.gitignore"

	[ ! -e "${_README}" ] &&
		echo "# ${_dirname}" >> "${_README}"

	[[ ! -e "${_IGNORE}" && -e "${_GITIGNORE}" ]] && 
		cp "${_GITIGNORE}" .gitignore
}

Select_add () {
	echo -e 'Enter on empty line indicates user is finished.\n'

	declare -a _ADDER
	while true; do
		read -a REPLY -rep 'git adding: '
		[[ ! "${REPLY}" ]] && 
			break
		for _valid in "${REPLY[@]}"; do
			[ -e "${_valid}" ] && 
				_ADDER+="${_valid} " || 
				echo -e "\033[38;5;196mfile: doesn't exist: '${_valid}'\033[00m"
			done
	done

	(( ${#_ADDER} )) && 
		git add ${_ADDER[@]} || 
		Prog_error 'noAdd'
}

Prompt_user () {

	local _CTRL_ADD=
	local _PROMPT='[ add -> commit ]:(y/n/[s]elect): '
	git status --short; echo

	read -p "${_PROMPT}" _response
	case "${_response}" in
		y | yes ) 
			git add . || 
				Prog_error 'noAdd'
			;;
		s | select )
			Select_add || 
				Prog_error 'noAdd'
			;;
		* )
			Prog_error 'noAdd'
			;;
	esac
}

Main_loop () {
	
	local _status=
	local _cmsg="${_SETUP['cmsg']}"

	readarray -d '\n' _status < <(git status --short || false) 
	[[ "${_status}" ]] || Prog_error 'noGit'

	(( ${_SETUP['templates']} )) && Template_files
	(( ${_SETUP['quiet']} )) && git add . || { 
		Prompt_user; echo; 
	}

	if [ -z "${_cmsg}" ]; then	
		printf -v _cmsg "\nPreStats:\n%s\nPostStats:\n%s\n" \
			"${_status}" \
			"$(git status --short)"
	fi

	git commit -m "${_cmsg}"
}

Parse_args () {
	declare -A _SETUP

	while [ -n "${1}" ]; do
		case "${1}" in
			-m | --cmsg )
				shift
				_SETUP['cmsg']="${1}"
				;;
			-q | --quiet )
				_SETUP['quiet']=1
				;;
			-t | --templates )
				_SETUP['templates']=1
				;;
			-h | --help )
				Usage
				;;
			* ) 
				Prog_error 'token'
				;;
		esac
		shift
	done

	Main_loop "${_SEUTP}"
}

Parse_args "${@}"

