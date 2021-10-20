#/bin/bash

# Configure Git --global's for user account (Ubuntu).
# Default editor is set as Vim, branch name is 'main' to mirror GitHub default.
# Username has no filter, email regex filters only alnum & ( ., -, _, @ ).
# SSH --keygen uses email associated with user in ~/.gitconfig.


prog_usage () {
	local PROGNAME="${0##*/}"
	_args='[ --basic ] [--colors ] [ --keygen ]'
	_kwargs='[ -u | --user <name> ][ -e | --email <gh_email> ]'
	printf '\n%s\n\t%s\n\t%s\n' "usage: ${PROGNAME}:" "${_args}" "${_kwargs}"
}


error_msg () {
	printf "\nExceptionRasied: ${1}"
}


set_git_config () {
	printf '>>> git config --global %s %s\n' "${1}" "${2}"
	git config --global "${1}" "${2}"
}


yn_clobber () {
	cat <<- EOF
		[ Safe_Clobber || No_Clobber ]
		KeyExistsError --> ${_config_key}
		Current Value --> ${_chk_config}
		New Value --> ${_config_val}
	EOF

	read -p 'Clobber? (y/n) ' _clobbering
	if [[ "${_clobbering}" =~ ^y$ ]]; then
		set_git_config "${_config_key}" "${_config_val}"
	else
		echo -e "\nNO CLOBBER\n"
	fi
}

chk_git_config () {
	# Check if config has been set before writing to it.
	# Jumps to yn_clobber function if key/value pair exists.
	local _config_key="${1}" _config_val="${2}"
	local _chk_config=="$(git config --global --get ${_config_key})"
	
	# No config key/val pair found (returns single '=').
	if [[ "${_chk_config}" =~ ^=$ ]]; then
		set_git_config "${_config_key}" "${2}"
	
	# Raised git-config error; error code printed.
	elif [[ "${?}" =~ ^[1-6]$ ]]; then
		error_msg "git_config_errCode(${?})" && return 1
	
	# Default is NoClobber; prompts before overwriting configs.
	else
		yn_clobber "${_config_key}" "${_chk_config}" "${_config_val}"
	fi
}


set_basic () {
	# Default branch name Git gives forks.
	chk_git_config 'init.defaultBranch' 'main'

	# Set the default editor Git uses; default is Vim.
	chk_git_config 'core.editor' 'vim'

	# Set colors: color.(status|branch|interactive|diff)=auto
	base_color=('color.status' 'color.branch' 'color.interactive' 'color.diff')
	for _col_config in "${base_color[@]}"; do 
		chk_git_config "${_col_config}" 'auto'
	done
	unset 'base_color' 
	
}


set_user () {
	# Set username and email: user.(name|email)
	if [[ "${1}" == '-u' ]]; then
		chk_git_config 'user.name' "${2}"
	else
		if [[ ! "${2}" =~ ^([[:alnum:]]|\.|\_|\-)+@([[:alnum:]]|\.)+\.[a-z]{2,5}$ ]]; then
			error_msg 'BAD-EMAIL\n' && return 1
		else
			chk_git_config 'user.email' "${2}"
		fi
	fi	
}

gen_ssh_key () {
	# TODO Can multiple id_ed25591 key be created?
	# TODO If comments have different emails cant see that being a porblem 
	[ -e "${HOME}/.ssh/id_ed25519" ] && echo '??? ~/.ssh exists ???' && return 1

	_email="$(git config --global --get user.email)"
	if [[ "${_email}" =~ ^=$ ]]; then
		echo 'Must have email associated with local Git first'
	else
		printf '\n>>> ssh-keygen -t id_ed25519 -C %s' "${_email}"
		#ssh-keygen -t id_ed25519 -C "${1}"
	
		printf '\n>>> eval "$(ssh-agent -s)"'
		#eval "$(ssh-agent -s)"

		printf '\n>>> ssh-add "%s/.ssh/id_ed25519"\n' "${HOME}"
		#ssh-add "${HOME}/.ssh/id_ed25519"
	fi
}

main_loop () {
	local _SSH=0
	declare -A user_custom
	while [ -n "$1" ]; do
		case "$1" in
			-u | --user )  
				shift; set_user '-u' "${1}"
				;;
			-e | --email )  
				shift; set_user '-e' "${1}"
				;;
			--basic )
				set_basic
				;;
			--keygen )
				_SSH='1'
				;;
			-k[0-9] )
				# TODO Enter custom key/value pairs
				shift; local _ckey="${1}"
				shift; local _cval="${1}"
				user_custom["${_ckey}"] = "${_cval}"
				echo "ADDED: ${_ckey} == ${user_custom["${_ckey}"]}"
				;;
			-h | --help )
				prog_usage && return 0
				;;
			* )
				error_msg "Unknown Parameter ${1}"
		esac
		shift
	done

	# Generate SSH public/private key pair
	[[ "${_SSH}" == '1' ]] && gen_ssh_key
}


if [[ "${#}" == 0 ]]; then
	prog_usage && exit 1
else
	echo
	main_loop "$@"
fi



