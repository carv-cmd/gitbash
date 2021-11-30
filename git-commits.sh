#!/bin/bash

#       _ _                
#  __ _(_) |_ __ ___ _ __  
# / _` | |  _/ _/ _ \ '  \ 
# \__, |_|\__\__\___/_|_|_|
# |___/                    
# 
# gitcom: Quick and simple `git (add|commit)` manager

PROGNAME=${0##*/}
GITBASH="${HOME}/bin/gitbash"

Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git commit manager

usage: ${PROGNAME} [ -m ] [ -q ] [ -t ]

Examples:
   ${PROGNAME} [ -q ][ -t ]
   ${PROGNAME} -t -m 'commitMsg'
   ${PROGNAME} -q -t -m 'commitMsg'

 Flags:
   -h | --help		= display this prompt.
   -m | --cmsg		= commit message (git commit -m '').
   -p | --push		= push upstream after committing changes.
   -q | --quiet		= dont prompt before 'add -> commit' (use wisely).
   -t | --templates	= create README.md & .gitignore files if doesn't exist.

EOF
exit 1
}

Prog_error () {
	declare -A ERR
	ERR['token']='unknown parameter'
	ERR['noAdd']='`git add` failed'
	ERR['noGit']='./.git does not exist in directory'
	ERR['noCom']='failed commit'
	ERR['push']='git push upstream failed'
	echo -e "\nraised: ${ERR[${1}]}"
	unset 'ERR'
	exit 1
}

Template_files () {
	# Generate template.gitignore then save in $GITBASH directory.
	# Create basic 'README.md' and '.gitignore' files if they dont exist.
	local CWD=$(pwd)
	local MK_README="${CWD}/README.md"
	local IGNORE_TEMPLATE="${CWD}/.gitignore"
	local GITIGNORE="${GITBASH}/template.gitignore"

	[ ! -e "${MK_README}" ] &&
		echo "# ${CWD##*/}" >> "${MK_README}"

	[[ ! -e "${IGNORE_TEMPLATE}" && -e "${GITIGNORE}" ]] && 
		cp "${GITIGNORE}" .gitignore
}

Select_add () {
	# I know `git commit --interactive` exists
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
		read -a REPLY -rep "Queue:[ ${_ADDER[@]}]<<< "
		
		if [[ "${REPLY}" == 'exit' ]]; then
			Prog_error 'noAdd'

		elif [[ ! "${REPLY}" ]]; then
			echo; read -p "git add ${_ADDER[@]} <<<(y/n): "
			[[ "${REPLY}" =~ ^(y|yes)$ ]] && break

		else
			printf '\033[0F\033[0J'
			for _valid in "${REPLY[@]}"; do
				[ -e "${_valid}" ] && 
					_ADDER+="${_valid} " || 
					echo -e "FilenameError: '${_valid}'\n"
			done
		fi

	done
	if (( ${#_ADDER} )); then 
		git add ${_ADDER[@]}
		unset '_ADDER' '_EXIT'
	else
		Prog_error 'noAdd'
	fi
}

Prompt_user () {
	# Ask-before-add-&-commit enabled by default.
	# (y|yes) commits everything listed by git status.
	# (s|select) lets user select specific files to add/commit.
	# Calling from scripts, bypass with '-q | --quiet' option.
	git status --short; echo
	local _PROMPT='[ add -> commit ]:(y/n/[s]elect): '
	read -p "${_PROMPT}" _response
	case "${_response}" in
		y | yes ) 
			git add . || 
				Prog_error 'noAdd'
			;;
		s | select )
			Select_add ||  # See Select_add '<<- here string'
				Prog_error 'noAdd'
			;;
		* )
			Prog_error 'noAdd'
			;;
	esac
}

Main_loop () {
	local STATUS=  # Store short status for auto commit msg.
	readarray -d '\n' STATUS < <(git status --short || false) 
	[[ ! ${STATUS} ]] && STATUS='null'

	# See `Template_files` comments.
	(( ${_SETUP['templates']} )) && 
		Template_files  
	
	# Pass --quiet option from scripts to silently git add.
	(( ${_SETUP['quiet']} )) &&
		git add . || Prompt_user  # See `Prompt_user` comments.

	# Generate pre -> post state commit msg if none supplied by user.
	local COMMIT_MSG="${_SETUP['cmsg']}"

	# Commit changes.
	if [[ -z "${COMMIT_MSG}" ]];then
		if [[ "${STATUS}" ]]; then	
			printf -v COMMIT_MSG "\nPreCommit:\n%s\nPostCommit:\n%s\n" \
				"${STATUS}" "$(git status --short)"

		elif [[ ! "${STATUS}" == 'null' ]]; then
			COMMIT_MSG="$(git status --short)" 
		fi
	fi
	git commit -m "${COMMIT_MSG}" || 
		Prog_error 'noCom'
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
			-p | --push )
				_SETUP['push']=1
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

	# Push upstream if -p flag has been set.
	if (( ${_SETUP['push']} )); then 
            git push origin $(git branch --show-current) || Prog_error 'push'
	fi
}

# Verify git history exists in CWD, otherwise exit 1.
[ -e "$(pwd)/.git" ] && 
	Parse_args "${@}" ||
	Prog_error 'noGit'

