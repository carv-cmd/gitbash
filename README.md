# gitbash
*Wrapper for Git on Ubuntu-20.04.*

---
## Setup Help
### /$HOME/bin
* *~/bin == $HOME/bin*

On your machine, start by creating the `~/bin` directory if it doesn't already exist. 
`~/bin` will be added to your `$PATH` variable upon logging out and back in.
This means any executable files in `~/bin` can be called globally like you would `cat`.
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
## Clone into ~/bin
```bash
cd ~/bin
git clone https://github.com/carv-cmd/gitbash.git
```

---
### Symlink `gitman`
Optionally you can create the symbolic link gitman -> [*gitbash/gitman.sh*](gitman.sh). 
* `gitman <subcmd> OPTIONS` can then be called anywhere.
```bash
# ln -s <resource_path> <link_name>
cd ~/bin
ln -s ./gitbash/manager.sh gitman
```

---
## Usage

**`gitman <subcmd> OPTIONS`**
* Try: `gitman <subcmd> --help`

---
| ***Subcommand*** | *Files* | *Description* |
|---|---|---|
| `gitman users` | [*`users.sh`*](bin/users.sh) | Git user setup & basic configuration |
| `gitman repo` | [*`repo.sh`*](bin/repo.sh) | Create upstream Git repositories |
| `gitman branch` | [*`branch.sh`*](bin/branch.sh) | Create, merge, delete; local & remote |
| `gitman commit` | [*`commit.sh`*](bin/commit.sh) | Git add-commit-push wrapper |
| `gitman upstream` | [*`upstream.sh`*](bin/upstream.sh) | Query upstream repositories |

The GitHub CLI (`gh`) is only required for working with remote github.com repos.
* To install the GitHub CLI ( `gh` ), simply `gitman install-gh-cli [--run]`.
* *Note this is only tested on Ubuntu20.04.*

---
### Authentication
An *SSH Key (Secure Shell)* or *PAT (Personal Access Token)* is required when working with upsreams.

#### [*SSH Keys*](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh) 
 * Run `gitman users --keygen` to generate a valid *ssh-key-pair* for you. 
 * See [**here**](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh),
 for instructions on adding this key to your GitHub account. 
 * See [*GIT-SSH.md*](/GIT-SSH.md) for details on setting up SSH.

```bash
ssh-keygen -t id_ed25519 -C '<github_email>@<email>.com'
cat ./gh-ssh-config.txt >> ~/.ssh/config
ssh -T gh
```

```bash
# For SSH with GH-CLI; `~/.config/gh/config.yml` needs to be modified.
# This can be done with your favorite text editor or sed.

# Modify record -> 'git_protocol: (https|ssh)'
[vim|nano] ~/.config/gh/config.yml

# Using `sed`, modify file inplace. Dryrun without [-i].
sed [-i] 's/^git_protocol: https/git_protocol: ssh/' ~/.config/gh/config.yml
```

---
**If you plan to use *HTTPS* remote connections, you will need a [*Personal Access Tokens (PAT)*](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).**
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

 
