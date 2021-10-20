#!/bin/bash


PROGNAME="${0##*/}"
_GITNAME="$(git config --get user.name)"
_LOCAL_GIT_DIR="${HOME}/git-repos"
_GITBASH="${0%/*}/gitbash"
_GITIGNORE="${_GITBASH}/template.gitignore"
_GITCOMMIT="${_GITBASH}/git-commits.sh"
# For complex filtering, uncomment and modify $_FILTER_WITH.
# Passed complete Graphql JSON response string for parsing.
_FILTER_WITH= #"${_GITBASH}/filter-repos.py"


Usage () {
	cat <<- EOF

${PROGNAME} - the stupid git repo manager

usage: ${PROGNAME} [ --new-repo ] [ -push-repo ] [ --query-remotes ]

Where:
${PROGNAME} [ -n | --new-repo ] name (location|default)
  - Create new version controlled directory and push to Github.com.
  - git-init defaults into $_LOCAL_GIT_DIR unless specified otherwise.
  - An attempt to create ${LOCAL_GIT_DIR} will be made before exiting on 1.

${PROGNAME} [ -p | --push-repo ] (existing|cwd)
  - Push an existing version controlled library to Github.com.
  - Prompts user before executing git (init, add, commit).
  - If any of the above fail, program exits w/o pushing upstream.

${PROGNAME} [ -q | --query-remotes ]
   - See all remotes listed under ${_GITNAME} on github.
   - PrettyPrint JSON response from 'gh api graphql query remotes'.

* When pushing new directories upstream, namespace collisions are checked first.
* If collision found, terminate w/o executing push upstream

EOF
unset '_LOCAL_GIT_DIR' '_GITIGNORE' '_GITNAME' 
exit 1
}

Prog_error () {
	declare -A ERR
	ERR['nullArg']='no parameters given'
	ERR['remClobber']='activated remote clobber protection'
	ERR['isDir']='activated local clobber protection'
	ERR['noDir']='local directory doesnt exist'
	ERR['noGit']='required .git/ does not exists in directory'

	echo -e "\nraised: \033[38;5;196;48;5;16m${ERR[${1}]} \033[00m"
	unset 'ERR'
	Usage
}

Prompt_user () {
	# Binary response prompter
	echo
	read -p "${1} (y/n): " _mkinit
	case "${_mkinit}" in
		y ) 
			return 0
			;;
		* )
			return 1
			;;
	esac
}

Query_remotes () {
	# Query GH-graphql for remote repositories.
	gh api graphql --paginate -f query='
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
		python3 "${_FILTER_WITH}" -N "${_dirname}" -J "${_json_response}" || { 
			Prog_error 'remClobber';
		} && return 0
	fi
	
	# If $_FILTER_FUNC unset; parse JSON response with shell expansion.
	# Relevant reponses extracted from JSON array with: *[##array%%]*
	# Search/Replace expansions operate on head then tail.
	readarray -d ',' _remote_repos < <(\
		_sliced="${_json_response##*[}";\
		echo "${_sliced%%]*}")

	for _rems in "${_remote_repos[@]}"; do
		_iremote="${_rems##*/}"; 
		if [[ "${_iremote%%\"*}" =~ ^"${_dirname}"$ ]]; then
			Prog_error 'remClobber'
		fi
	done 
}

Create_push_remote () {  
	# Create basic public remote on GitHub.com
	# Set main upstream establishing references with remote
	gh repo create --public --confirm "${_dirname}" && 
		git push --set-upstream origin "$(git branch --show-current)"
}

Commit_repo () {
	# Commit current repo before pushing upstream.

	local _cmsg="${2}"
	local _cwd="$(pwd)"

	[ ! -e "${_cwd}/README.md" ] &&
		echo "# ${_dirname}" >> 'README.md'

	[ ! -e "${_cwd}/.gitignore" ] && 
		cp "${_GITIGNORE}" .gitignore

	local _tracking="$(git status --short)"
	echo -e "\n${_tracking}\n"

	Prompt_user 'Commit current state?' && {
		git add . &&
		git commit -m "CommitState: ${_tracking}" &&
		git status;
	} || return 1
}

Push_existing_repo () {
	# Push local tracked repository to GitHub.

	if [ -n "${1}" ]; then 
		{ [ -e "${1}" ] && cd "${1}"; } || 
			Prog_error 'noDir'
	else
		[[ "$(pwd)" =~ \.git$ ]] && cd ..
	fi

	local _repo="$(pwd)"
	local _dirname="${_repo##*/}"
	Check_remotes "${_dirname}"

	[ ! -e "${_repo}/.git" ] && {
		Prompt_user "git init ${_dirname}" &&
		git init "$(pwd)";
	} || Prog_error 'noGit'

	Commit_repo "${_dirname}" &&
		git branch -m 'main' && 
		Create_push_remote "${_dirname}"
}

New_blank_repo () {
	# Create bare local tracked repo, and push to GitHub remote
	# Any new blank repos created in ${_LOCAL_GIT_DIR} unless specified

	[ -z "${_dirname}" ] && 
		Prog_error 'nullArg'

	local _newdir= 
	if [ -n "${1}" ]; then
		_newdir="${1}/${_dirname}"
	else
		[ ! -e "${_LOCAL_GIT_DIR}" ] && 
			mkdir "${_LOCAL_GIT_DIR}" && 
			Prog_error 'noGit'
		_newdir="${_LOCAL_GIT_DIR}/${_dirname}";
		
	fi

	[ -e "${_newdir}" ] && 
		Prog_error 'isDir'

	Check_remotes "${_dirname}" && {
		git init "${_newdir}" && 
		cd "${_newdir}" && 
		git checkout -b 'main' &&
		Commit_repo "${_dirname}" &&
		Create_push_remote "${_dirname}";
	} || return 1
}

Main_loop () {
	local _param="${1}"; shift
	local _dirname="${1}"; shift
	case "${_param}" in
		-n | --new-repo )
			New_blank_repo "${1}" "${_dirname}"
			;;
		-p | --push-existing )
			Push_existing_repo "${_dirname}"
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

