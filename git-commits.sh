#!/bin/bash

# gitcom: Quick and simple `git (add|commit)` manager


PROGNAME="${0##*/}"
_GITBASH="${0%/*}/gitbash"


Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git commit manager

usage: ${PROGNAME} [ -m ] [ -q ] [ -t ]

Examples:
   ${PROGNAME} [ -q ]
   ${PROGNAME} -t -m 'commitMsg'
   ${PROGNAME} -q -t -m 'commitMsg'

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
	ERR['noGit']='./.git does not exist in directory'
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
	cat <<- 'EOF'

	* Enter filenames to `git add` from listing above.
	* One or more filenames can be passed on each line entry.
	* Pass string 'exit' to exit without making any changes.
	* Add & Commit changes with 2 blank newlines.
	* Staged command printed for confirmation before execution.
	* Duplicates are ignored; i.e. `git add x.py x.py` == `git add x.py`

	EOF
	declare -a _ADDER
	while true; do

		read -a REPLY -rep "Queue[ ${_ADDER[@]}]<<< "
		
		if [[ "${REPLY}" == 'exit' ]]; then
			Prog_error 'noAdd'
		elif [[ ! "${REPLY}" ]]; then
			echo -e "\ngit add ${_ADDER[@]}\n"
			read -p 'execute(y/n)? ' _EXIT
			[[ "${_EXIT}" == 'y' ]] && unset '_EXIT' && break
		else
			printf '\033[0F\033[0J'
			for _valid in "${REPLY[@]}"; do
				[ ! -e "${_valid}" ] &&
					echo -e "FilenameError: '${_valid}'\n" ||
					_ADDER+="${_valid} "
			done
		fi

	done
	if (( ${#_ADDER} )); then 
		git add ${_ADDER[@]}
	else
		Prog_error 'noAdd'
	fi
}

Prompt_user () {
	# Ask-before-add-&-commit enabled by default.
	# For scripts, bypass with '-q | --quiet' option.

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
	
	local COMMIT_MSG="${_SETUP['cmsg']}"

	local _status=
	readarray -d '\n' _status < <(git status --short || false) 
	[[ "${_status}" ]] || 
		Prog_error 'noGit'

	(( ${_SETUP['templates']} )) && 
		Template_files

	(( ${_SETUP['quiet']} )) && 
		git add . || 
		Prompt_user

	if [ -z "${COMMIT_MSG}" ]; then	
		_FORMAT="\nPreCommit:\n%s\nPostCommit:\n%s\n" 
		printf -v COMMIT_MSG "${_FORMAT}" "${_status}" "$(git status --short)"
		unset '_FORMAT'
	fi

	echo
	git commit -m "${COMMIT_MSG}"
}

Parse_args () {
	# Parse user input & populate hash table for Main_loop.

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

