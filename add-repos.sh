#!/bin/bash


PROGNAME="${0##*/}"
_GITBASH="${0%/*}/gitbash"
_GITCOM="${_GITBASH}/git-commits.sh"
_LOCAL_GITS="${HOME}/git-repos"
_GITNAME="$(git config --get user.name)"

# For complex filtering, uncomment and modify $_FILTER_WITH.
# Passed complete Graphql JSON response string for parsing.
_FILTER_WITH= #"${_GITBASH}/filter-repos.py"


Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git repo manager

usage: ${PROGNAME} [ --new-repo ] [ -push-repo ] [ --query-remotes ]

Where:
${PROGNAME} [ -n | --new-repo ] name (location|default)
  * Create new version controlled directory and push to Github.com.
  * git-init defaults into $_LOCAL_GITS unless specified otherwise.
  * An attempt to create ${_LOCAL_GITS} will be made before exiting on 1.

${PROGNAME} [ -p | --push-repo ] (existing|cwd)
  * Push an existing version controlled library to Github.com.
  * Prompts user before executing git (init, add, commit).
  * If any of the above fail, program exits w/o pushing upstream.

${PROGNAME} [ -q | --query-remotes ]
   * See all remotes listed under ${_GITNAME} on github.
   * PrettyPrint JSON response from 'gh api graphql query remotes'.

* When pushing new directories upstream, namespace collisions are checked first.
* If collision found, terminate w/o executing push upstream

EOF
unset '_LOCAL_GITS' '_GITIGNORE' '_GITNAME' 
exit 1
}

Prog_error () {
	declare -A ERR
	ERR['nullArg']='no parameters given'
	ERR['remClobber']='activated remote clobber protection'
	ERR['isDir']='activated local clobber protection'
	ERR['noDir']='local directory doesnt exist'
	ERR['noGit']='required .git/ does not exists in directory'
	ERR['gitCom']='must add and commit current state before pushing remote'
	echo -e "\nraised: ${ERR[${1}]}"
	unset 'ERR'
	exit 1
}

Prompt_user () {
	# Binary response prompter
	echo
	read -p "${1} (y/n): " _mkinit
	case "${_mkinit}" in
		y | yes ) 
			return 0
			;;
		* )
			exit 1
			;;
	esac
}

Query_remotes () {
	# Query GH-graphql for remote repositories.
	# This is the query string straight from gh man pages.
	# JSON is easy to parse and it pretty prints so here we are.

	gh api graphql --paginate --cache '60s' -f query='
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
	'
}

Check_remotes () {
	# Check remote repositories for conflicting names.
	local _iremote=
	local _remote_repos=
	local _json_response="$(Query_remotes)"
	
	# Implement complex filters in the script located at "$_GITBASH".
	# Currently takes dirname and serialized json response as input.
	if [[ "${_FILTER_WITH}" ]]; then 
		python3 "${_FILTER_WITH}" -N "${DIRNAME}" -J "${_json_response}" ||
			Prog_error 'remClobber'
		return 0
	fi
	
	# If $_FILTER_FUNC unset; parse JSON response with shell expansion.
	# Relevant reponses extracted from JSON array with: *[##array%%]*
	readarray -d ',' _remote_repos < <(\
		_sliced="${_json_response##*[}";\
		echo "${_sliced%%]*}")

	for _rems in "${_remote_repos[@]}"; do
		_iremote="${_rems##*/}"; 
		if [[ "${_iremote%%\"*}" =~ ^"${DIRNAME}"$ ]]; then
			Prog_error 'remClobber'
		fi
	done 
}

Create_push_remote () {  
	# Create basic public remote on GitHub.com
	# Set main upstream establishing remote references.
	gh repo create --public --confirm "${DIRNAME}" &&
		git push --set-upstream origin "$(git branch --show-current)"
}

Push_existing_repo () {
	# Determine which directory to push and setup for push.
	if [ -z "${POS_ARG}" ]; then
		Prompt_user 'Push cwd? '
	elif [[ -e "${POS_ARG}" ]]; then
		cd "${POS_ARG}" || Prog_error 'noDir'
	elif [[ "$(pwd)" =~ \.git$ ]]; then
		cd ..
	fi

	local _repo="$(pwd)"
	local DIRNAME="${_repo##*/}"
	Check_remotes "${DIRNAME}"

	if [ ! -e "${_repo}/.git" ]; then
		Prompt_user "git init ${DIRNAME}"
		git init "$(pwd)" || 
			Prog_error 'noGit'
	fi

	# $GITCOM generates README.md and .gitignore files if they dont exist.
	# Additionally the user is prompted before any changes are made
	# Supress prompt by including the '-q' flag in gitcom's call.
	"${_GITCOM}" -t &&
		git branch -m 'main' && 
		Create_push_remote "${DIRNAME}" 
}

New_blank_repo () {
	# Create bare local tracked repo, and push to GitHub remote
	# Any new blank repos created in ${_LOCAL_GITS} unless specified

	local _newdir= 
	if [ -n "${1}" ]; then
		_newdir="${1}/${DIRNAME}"
	else
		if [ ! -e "${_LOCAL_GITS}" ]; then
			mkdir "${_LOCAL_GITS}" || Prog_error 'noGit'
		fi
		_newdir="${_LOCAL_GITS}/${DIRNAME}"
	fi

	[ -e "${_newdir}" ] && Prog_error 'isDir'

	git init "${_newdir}" && 
		cd "${_newdir}" && 
		git checkout -b 'main' && 
		"${_GITCOM}" -t -q &&
		Create_push_remote "${DIRNAME}" ||
		Prog_error 'noGit'
}

Clone_gh_repo () {
	if [[ -z "${POS_ARG}" && -e "${_LOCAL_GITS}" ]]; then 
		cd "${_LOCAL_GITS}"
	elif [ -e "${POS_ARG}" ]; then
		cd "${POS_ARG}"
	else
		Prog_error 'noGit'
	fi
	gh repo clone "${DIRNAME}" 
	cd -
}

Main_loop () {
	local OPTION="${1}"; shift
	local DIRNAME="${1}"; shift
	local POS_ARG="${1}"

	case "${OPTION}" in
		-c | --gh-clone )
			Clone_gh_repo "${DIRNAME}" "${POS_ARG}" 
			;;
		-n | --new-repo )
			[ -z "${DIRNAME}" ] && Prog_error 'nullArg'
			Check_remotes "${DIRNAME}" || Prog_error 'isDir'
			New_blank_repo "${DIRNAME}" "${POS_ARG}" 
			;;
		-p | --push-existing )
			Push_existing_repo "${DIRNAME}" "${POS_ARG}" 
			;;
		-q | --query-remotes )
			Query_remotes 
			;;
		-h | * )
			Usage
			;;
		esac
}

if [[ ! "${@}" ]]; then
	Prog_error 'nullArg'
else
	Main_loop "${@}"
fi

