# gitbash

*Wrappers for Git on Ubuntu-20.04.*
 * *This is not a Git strategy!* 
 * *Just a tool to help assist in creating one.*

## Setup
Note: `~/bin` == `$HOME/bin`

On your machine create the `~/bin` directory if it doesn't already exist.
When you logout and log back on the `$PATH` variable will be updated with `/home/$USER/bin`.
Any scripts placed in `~/bin` can then be called globally just like `cat` or `git init`.
This may also work with `source ~/.bashrc` but the previous method is more reliable.

Next you'll want to clone the *gitbash* repository into *~/bin*.
```bash
[ ! -d ~/bin ] && mkdir ~/bin
cd ~/bin && git clone https://github.com/carv-cmd/gitbash.git
```

Optionally you can create symbolic links as to shorten the command calls.
```bash
sym_links=( repos commits branches )
if cd ~/bin; then
    for file in ${sym_links[@]}; do
        ln -s ./gitbash/git-$file.sh ./g$file
    done
fi    
```

These scripts require an *SSH Key* and a *PAT*;

[*SSH Keys*](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh) 
 * The script `git-users.sh` has an option to generate a valid *ssh-key-pair* for you. 
 * See [**here**](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh),
 for instructions on adding this key to your GitHub account. 
 * Additionally `git-users.sh --help` will display details about ssh key generation.

[*Personal Access Tokens (PAT)*](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). 
* For details about PAT, see 
[**here**](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats)
* Create a token on GitHub.com and add to `~/.bashrc` file with the following:
```bash
# Token should start with 'ghp_*'.
TOKEN="ghp_<new_token>"
echo "GH_TOKEN=$TOKEN" >> ~/.bashrc
source ~/.bashrc
```

---
## Usage
---
| ***Helper Scripts*** | Description |
|---|---|
| `git-users.sh` | Set basic global configurations (~/.gitconfig) |
| `install-gh-cli.sh` | Installer for GitHub CLI ( `gh` )

If you want to use SSH with GH-CLI, `~/.config/gh/config.yml` needs to be modified as such;
* `vi|vim|nano ~/.config/gh/config.yml`
* Change `git_protocol: https` to `git_protocol: ssh` 

---
| ***Workflow Scripts*** | Description |
|---|---|
| `repos` -> `git-repos.sh` | Git repository manager |
| `commits` -> `git-commits.sh` | Git commit manager |
| `branches` -> `git-branches.sh` | Git branch manager |
 
