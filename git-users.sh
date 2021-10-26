#/bin/bash

# Configure Git --global's for user account (Ubuntu).
# Default editor is set as Vim, branch name is 'main' to mirror GitHub default.
# Username has no filter, email regex filters only alnum & ( ., -, _, @ ).
# SSH --keygen uses email associated with user in ~/.gitconfig.

PROGNAME="${0##*/}"

Usage () {
	cat <<- EOF

usage: 
  ${PROGNAME} --user-info <name> <gh_email> 
  ${PROGNAME} [ --basic ] [ --keygen ] [ --token <gh_token> ]

Flags:
  --user-info	= set Git username and email for ${USER}
  --basic	= set autocolor, editor=vim and default_branch_name=main
  --keygen	= generate id_25519 ssh key for github over ssh
  --token	= add token generated for 'gh auth login'
	
EOF
exit 1
}

Prog_error () {
	declare -A ERR
	ERR['000']='null input'
	ERR['001']='invalid input'
	ERR['002']='user.name conflict'
	ERR['003']='user.email conflict'
	ERR['004']='ssh key conflict'
	ERR['005']='gh token conflict'
	echo -e "\nrasied: ${ERR[${1}]}\n"
	unset 'ERR' 
	exit 1
}

Add_ssh_key () {
	# TODO Can multiple id_ed25591 key be created?
	[ -e "${HOME}/.ssh/id_ed25519" ] && Prog_error '004'

	USER_EMAIL="$(git config --global --get user.email)"
	[[ ! "${USER_EMAIL}" ]] && 
		Prog_email '003'
	
	ssh-keygen -t id_ed25519 -C "${USER_EMAIL}" &&
		eval "$(ssh-agent -s)" &&
		ssh-add "${HOME}/.ssh/id_ed25519" && 
		cat "${HOME}/.ssh/id_ed25519"
}

Add_gh_token () {
	[[ "$(grep 'GH_TOKEN' "${HOME}/.bashrc")" ]] && Prog_error '005'

	if [ -n "${ADD_TOKEN}" ]; then
		echo "# Added: $(date +%D)" >> "${HOME}/.bashrc"
		echo "export GH_TOKEN='${ADD_TOKEN}'" >> "${HOME}/.bashrc"
		source "${HOME}/.bashrc"
	fi
	unset 'ADD_TOKEN'
}

Set_git_config () {

	local CHK_CONFIG="$(git config --global --get ${1})"
	if [[ ! "${CHK_CONFIG}"  ]]; then
		git config --global "${1}" "${2}" || Prog_error '003'
	else
		echo "Fatal: '${1} ${CHK_CONFIG}' <- ${2}"
	fi
}

Set_basic () {
	# Default branch name Git gives forks.
	Set_git_config 'init.defaultBranch' 'main'

	# Set the default editor Git uses; default is Vim.
	Set_git_config 'core.editor' 'vim'

	# Set colors: color.(status|branch|interactive|diff)=auto
	BASE_COL=('status' 'branch' 'interactive' 'diff')
	for SET_COL in "${BASE_COL[@]}"; do 
		Set_git_config "color.${SET_COL}" 'auto'
	done
}

Set_user_info () {
	# Set Git $1:username and $2:email.
	if [[ "${1}" && "${2}" ]]; then
		if [[ "${2}" =~ ^([[:alnum:]]|\.|\_|\-)+@([[:alnum:]]|\.)+\.[a-z]{2,5}$ ]]; then
			Set_git_config 'user.name' "${1}"
			Set_git_config 'user.email' "${2}"
		else
			Prog_error '003'
		fi
	else
		Prog_error '002'
	fi
}

Main_loop () {
	while [ -n "${1}" ]; do
		case "${1}" in
			--basic )
				Set_basic
				;;
			--user-info )  
				shift
				Set_user_info "${1}" "${2}"
				shift
				;;
			--keygen )
				GEN_SSH_KEY=1
				;;
			--token )
				shift
				ADD_TOKEN="${1}"
				;;
			-h | --help )
				Usage
				;;
			* )
				Prog_error '000'
		esac
		shift
	done

	# Generate SSH id_ed25519 public/private key pair
	[[ "${GEN_SSH_KEY}" ]] && Add_ssh_key

	# Add `export GH_TOKEN=...` to $USER/.bashrc
	[[ "${ADD_TOKEN}" ]] && Add_gh_token "${ADD_TOKEN}"
}


if [[ ! "${@}" ]]; then
	Usage
else
	Main_loop "$@"
fi



