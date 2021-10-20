#!/bin/bash

# gitcom: Quick and simple `git (add|commit)` manager

PROGNAME="${0##*/}"
_GITBASH="${0%/*}/gitbash"

Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git commit manager

usage: ${PROGNAME} [ -b ] [ -m ] [ -q ] [ -t ]

Examples:
   ${PROGNAME} -t -q -b 'main' -m 'commitMsg'
   ${PROGNAME} -q -t
   ${PROGNAME} -m 'commitMsg'

 Where:
   -b | --branch		= working branch to user
   -m | --cmsg			= commit message (git commit -m '')
   -q | --quiet			= dont prompt user before making changes (use wisely)
   -t | --templates		= generate README.md & .gitignore files if ! exist

EOF
exit 1
}

Prog_error () {
	echo
	declare -A ERR
	#ERR['']=''
	unset 'ERR'
	Usage
}

Template_files () {
	# Generate basic 'README.md' and '.gitignore' files if they dont exist.

	local _CWD="$(pwd)"
	local _README="${_CWD}/README.md"
	local _IGNORE="${_CWD}/.gitignore"
	local _GITIGNORE="${_GITBASH}/template.gitignore"

	#echo -e "\n* CURDIR: ${_CWD}\n* README: ${_README}\n*.ignore: ${_IGNORE}\n"
	[ ! -e "${_README}" ] &&
		echo -e "echo '# ${_dirname}' >> ${_README}"
		# echo "# ${_dirname}" >> "${_README}"

	[[ ! -e "${_IGNORE}" && -e "${_GITIGNORE}" ]] && 
		echo "cp ${_GITIGNORE} .gitignore"
		# cp "${_GITIGNORE}" .gitignore
}


prompt_user () {
	# `git add` prompter

	local _CTRL_ADD=
	local _PROMPT='[ add -> commit ]:(y/n/[s]elect): '

	git status --short && {
		echo; read -p "${_PROMPT}" _response; echo
	} || return 1

	case "${_response}" in
		y | yes ) 
			#git add . || return 1
			echo "git add . || return 1"
			;;
		s | select )
			read -p 'Add Files: ' _CTRL_ADD; echo
			[ -n "${_CTRL_ADD}" ] && 
				echo "git add "${_CTRL_ADD}" || return 1"
			;;	
		* )
			return 1
			;;
	esac
}


main_loop () {

	local _status=
	readarray -d '\n' _status < <(git status --short || false) 
	[ -z "${_status}" ] && return 1

	[[ "${SETUP['templates']}" ]] && 
		Template_files

	if [[ "${SETUP['quiet']}" ]]; then
		echo "git add ."
		# git add .
	else
		prompt_user || exit 1
	fi

	[ -z "${SETUP['msg']}" ] && 
		_msg="\n\n${_status}\nPOST.ADD:\n$(git status --short)"

	echo -e "\ngit commit -m '${_msg}'\n" 
	# git commit -m "${_msg}"
}


parse_args () {
	declare -A _SETUP
	local _msg= 
	local _quiet=

	while [ -n "${1}" ]; do
		case "${1}" in
			-m | --cmsg )
				shift
				_SETUP['cmsg']="${1}"
				;;
			-q | --quiet )
				_SETUP['quiet']=0
				;;
			-t | --templates )
				_SETUP['templates']=0
				;;
			* ) 
				 Usage
				;;
		esac
		shift
	done
	main_loop "${_SEUTP}"
}

[ -z "${@}" ] && 
	Usage || 
	parse_args "${@}"

