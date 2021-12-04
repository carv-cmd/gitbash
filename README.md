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
 ```bash
 mkdir ~/bin
 exit
 <login>
 # This should return a long string.
 env | grep "^PATH=.*:$HOME/bin:.*"
 ```
> Note this is not requied to execute bash scripts.
> * Given: ***/home/user/foo/bar/baz/commits.sh***
>  1) `cd /home/user/foo/bar/baz && ./commits.sh` 
>  2) `~/foo/bar/baz/commits.sh`
>  3) `cd ~/bin && ln -s ~/foo/bar/baz/commits.sh && commits.sh`

---
### Symlinks
You can make symbolic links to shorten the command calls. 
 * You can create these *before* or *after* cloning ***gitbash***.
 * If they were created before `git clone` ignore the red names (*broken links*), git clone will fix them.
```bash
# ln -s <resource_path> <link_name>
cd ~/bin
ln -s ./gitbash/manager.sh gitman
```

---
### Authentication
These scripts require an *SSH Key (Secure Shell)* or *PAT (Personal Access Token)*:

#### [*SSH Keys*](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh) 
 * The script `git-users.sh` has an option to generate a valid *ssh-key-pair* for you. 
 * See [**here**](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh),
 for instructions on adding this key to your GitHub account. 
 * Additionally `git-users.sh --help` will display details about ssh key generation.

On the Linux side you essentially do the following, 
see [*here*](/git-ssh.md) for more details:
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

# SEE THE END OF THIS README FOR GH-INSTALLER.
# If you want to use SSH with GH-CLI; `~/.config/gh/config.yml` needs to be modified.
# This can be done with your favorite text editor or sed.

# Modify record -> 'git_protocol: (https|ssh)'
vi|vim|nano ~/.config/gh/config.yml

# Using `sed` to modify file inplace. 
# Run without '-i' option to perform dryrun.
sed -i 's/^git_protocol: https/git_protocol: ssh/' ~/.config/gh/config.yml
```

#### [*Personal Access Tokens (PAT)*](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). 
* For more details about PAT formats, see 
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
To install the GitHub CLI ( `gh` )
* Use: `gitman install-gh-cli --run` 

`gitman <subcmd> OPTIONS` is a wrapper for these scripts
* Try: `gitman <subcmd> --help`

---
| ***Workflows*** | *Files* | *Description* |
|---|---|---|
| `gitman user` | `users.sh` | Git user config manager |
| `gitman repo` | `repo.sh` | Git repository manager |
| `gitman branch` | `branche.sh` | Git branch manager |
| `gitman commit` | `commit.sh` | Git commit manager |
| `gitman upstream` | `upstream.sh` | Query upstream repositories |
---
 
