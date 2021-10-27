#/bin/bash

PROGNAME="${0##*/}"
GITBASH="${HOME}/bin/gitbash"
GITCOM="${GITBASH}/git-commits.sh"
LOCAL_GITS="${HOME}/git-repos"
GITNAME="$(git config --get user.name)"

# For complex filtering, uncomment and modify $_FILTER_WITH.
# Passed complete Graphql JSON response string for parsing.
_FILTER_WITH= #"${GITBASH}/filter-repos.py"

# TODO Update usage output.
Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git repo manager

usage: ${PROGNAME} [ --new-repo ] [ -push-repo ] [ --query-remotes ]

Where:
${PROGNAME} [ -n | --new-repo ] name (location|default)
  * Create new version controlled directory and push to Github.com.
  * git-init defaults into $LOCAL_GITS unless specified otherwise.
  * An attempt to create ${LOCAL_GITS} will be made before exiting on 1.

${PROGNAME} [ -p | --push-repo ] (existing|cwd)
  * Push an existing version controlled library to Github.com.
  * Prompts user before executing git (init, add, commit).
  * If any of the above fail, program exits w/o pushing upstream.

${PROGNAME} [ -q | --query-remotes ]
   * See all remotes listed under ${GITNAME} on github.
   * PrettyPrint JSON response from 'gh api graphql query remotes'.

* When pushing new directories upstream, namespace collisions are checked first.
* If collision found, terminate w/o executing push upstream

EOF
unset 'LOCAL_GITS' 'GITIGNORE' 'GITNAME' 
exit 1
}

Prog_error () {
	declare -A ERR
	ERR['nullArg']='no parameters given'
	ERR['remClobber']='activated remote clobber protection'
	ERR['isDir']='activated local clobber protection'
	ERR['noDir']='local directory doesnt exist'
	ERR['isGit']='.git/ already exists in directory'
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

	gh api graphql --paginate --cache '15s' -f query='
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
	local NEW_REMOTES=
	local REMOTE_REPOS=
	local JSON_RESPONSE="$(Query_remotes)"
	
	# Implement complex filters in the script located at "$GITBASH".
	# Currently takes dirname and serialized json response as input.
	if [[ "${_FILTER_WITH}" ]]; then 
		python3 "${_FILTER_WITH}" -N "${DIRNAME}" -J "${JSON_RESPONSE}" ||
			Prog_error 'remClobber'
		return 0
	fi
	
	# If $_FILTER_FUNC unset; parse JSON response with shell expansion.
	# Relevant reponses extracted from JSON array with: *[##array%%]*
	readarray -d ',' REMOTE_REPOS < <(\
		SLICED="${JSON_RESPONSE##*[}";\
		echo "${SLICED%%]*}")

	for _rems in "${REMOTE_REPOS[@]}"; do
		NEW_REMOTES="${_rems##*/}"; 
		if [[ "${NEW_REMOTES%%\"*}" =~ ^"${DIRNAME}"$ ]]; then
			Prog_error 'remClobber'
		fi
	done 
}

Create_push_remote () {  
	# Create basic public remote on GitHub.com
	# Set main upstream establishing remote references.
	gh repo create --public --confirm "${DIRNAME}" &&
		git push --set-upstream origin "$(git branch --show-current)" &&
		git checkout -b 'develop'
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

	local REPO="$(pwd)"
	local DIRNAME="${REPO##*/}"
	Check_remotes "${DIRNAME}"

	if [ ! -e "${REPO}/.git" ]; then
		Prompt_user "git init ${DIRNAME}"
		git init "$(pwd)" || Prog_error 'noGit'
	else
		Prog_error 'noGit'
	fi

	# $GITCOM generates README.md and .gitignore files if they dont exist.
	# Additionally the user is prompted before anything gets clobbered.
	# Supress prompt by including the '-q' flag in gitcom's call.
	"${GITCOM}" -t && 
		git branch -m 'main' && 
		Create_push_remote "${DIRNAME}" 
}

New_blank_repo () {
	# Create bare local tracked repo, and push to GitHub remote
	# Any new blank repos created in ${LOCAL_GITS} unless specified

	local _newdir= 
	[[ "${POS_ARG}" == '.' ]] &&
		_newdir="$(pwd)/${DIRNAME}" ||
		_newdir="${LOCAL_GITS}/${DIRNAME}"

	[ -e "${_newdir}" ] && 
		Prog_error 'isDir'

	git init "${_newdir}" && 
		cd "${_newdir}" && 
		git checkout -b 'main' && 
		"${GITCOM}" -t -q && 
		Create_push_remote "${DIRNAME}" && 
		return 0
	
	Prog_error 'noGit'
}

Clone_gh_repo () {
	if [[ -z "${POS_ARG}" ]]; then 
		cd "${LOCAL_GITS}"
	elif [ -e "${POS_ARG}" ]; then
		cd "${POS_ARG}"
	else
		Prog_error 'noDir'
	fi

	gh repo clone "${DIRNAME}" 
	git checkout -b 'develop'
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
elif [ ! -e "${LOCAL_GITS}" ]; then
	mkdir "${LOCAL_GITS}" || Prog_error 'noGit'
fi

Main_loop "${@}"

