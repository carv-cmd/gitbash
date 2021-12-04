# gitbash

*Wrappers for Git on Ubuntu-20.04.*
 * *This is not a Git strategy!* 
 * *Just a tool to help assist in creating one.*

## Setup

### /$HOME/bin
* *~/bin == $HOME/bin*

On your machine, start by creating the `~/bin` directory if it doesn't already exist. 
`~/bin` will be added to your `$PATH` variable upon logging out and back in.
This means any executable scripts in `~/bin` can be called globally like `cat` or `git init`.
Then verify the `$PATH` variable has been updated with `/home/$USER/bin` (Ubuntu).
 * `mkdir ~/bin; exit`
 * `<login>; env | grep PATH`

> Note this is not requied to execute bash scripts.
> * Given: ***/home/user/foo/bar/baz/git-commits.sh***
>  1) `cd /home/user/foo/bar/baz && ./git-commits.sh` 
>  2) `~/foo/bar/baz/git-commits.sh`
>  3) `cd ~/bin && ln -s ~/foo/bar/baz/git-commits.sh`
---
### Symlinks
Optionally you can create symbolic links as to shorten the command calls. 
 * You can create these *before* or *after* cloning ***gitbash***.
 * If they were created before `git clone` ignore the red names (*broken links*), git clone fixes them.
```bash
# ln -s <resource_path> <link_name>

cd ~/bin
ln -s ./gitbash/git-repos.sh gitrepo
ln -s ./gitbash/git-branches.sh gitbran
ln -s ./gitbash/git-commits.sh gitcom
```
---
### Authentication
These scripts require an *SSH Key* and a *PAT*;

[*SSH Keys*](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh) 
 * The script `git-users.sh` has an option to generate a valid *ssh-key-pair* for you. 
 * See [**here**](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh),
 for instructions on adding this key to your GitHub account. 
 * Additionally `git-users.sh --help` will display details about ssh key generation.

On the Linux side you essentially do the following:
```txt  
# gh-ssh-config.txt
Host gh
    Hostname github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    Port 22
    Protocol 2
    PreferredAuthentications publickey
```
```bash

ssh-keygen -t id_ed25519 -C '<github_email>@<email>.com'
cat ./gh-ssh-config.txt >> ~/.ssh/config
ssh -T gh
```

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
### Clone
Finally you'll want to clone the *gitbash* repository into *~/bin*.
* `cd ~/bin && git clone https://github.com/carv-cmd/gitbash.git`

---
## Usage
---
| ***Helper Scripts*** | Description |
|---|---|
| `git-users.sh` | Set basic global configurations (~/.gitconfig) |
| `install-gh-cli.sh` | Installer for GitHub CLI ( `gh` )
||
| ***Workflow Scripts*** | Description |
| `gitrepo` -> `git-repos.sh` | Git repository manager |
| `gitbran` -> `git-branches.sh` | Git branch manager |
| `gitcom` -> `git-commits.sh` | Git commit manager |
---
If you want to use SSH with GH-CLI; `~/.config/gh/config.yml` needs to be modified.
 * This can be done with your favorite text editor or the following `sed` commands.
```bash
# Modify record -> 'git_protocol: (https|ssh)'
vi|vim|nano ~/.config/gh/config.yml

# Use `sed` to modify file inplace. 
# Run without '-i' option to dryrun modifications.
sed -i 's/^git_protocol: https/git_protocol: ssh/' ~/.config/gh/config.yml
```
 
