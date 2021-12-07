# gitbash
*Wrapper for Git on Ubuntu-20.04.*

## Setup

**Ideally create *~/bin* if it doesn't exist.**
* The next time you logoff/login your ***$PATH*** variable will be updated to search in ***~/bin***.
```bash
mkdir ~/bin
exit
<login>
```

<details><summary>What is $PATH?</summary>
<p>
 
Clipped from `man bash`
```txt
PATH   
   The search path for commands. It is a colon-separated list of directories 
   in which the shell looks for commands (see COMMAND EXECUTION below). 
   A zero-length (null) directory name in the value of PATH indicates the current directory. 
   A null directory name may appear as two adjacent colons, or as an initial or trailing colon.   
   The default path is system-dependent, and is set by the administrator who installs bash.  
   A common value is ``/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin''.
```

See [***here***](https://askubuntu.com/questions/60218/how-to-add-a-directory-to-the-path) 
for details on setting custom ***$PATH*** directories.

---

**To verify your *$PATH* has been updated with */home/$USER/bin* run the command below**
* Your full ***$PATH*** variable should be returned, otherwise `grep` exits on error.
```bash
env | grep "^PATH=.*:$HOME/bin:.*$"
```
 
---
</p>
</details>
 
## Clone Repository
```bash
cd ~/bin || cd /usr/bin # Optional
git clone https://github.com/carv-cmd/gitbash.git
```

### Symlink `gitman`
Create the symbolic link ***$PATH/gitman*** -> [*gitbash/gitman.sh*](gitman.sh). 
* Depending where you cloned *gitbash*, fill in *$GITBASH_LOCATION* respectively. 
```bash
# Change into $PATH/directory
cd ~/bin || cd /usr/bin || cd /$DIR_ON_PATH

# ln -s <resource_path> <link_name>
ln -s $GITBASH_LOCATION/gitbash/manager.sh gitman

# See `gitman` features
gitman help
```

## Usage
### **`gitman <subcmd> OPTIONS`**
* Try: `gitman <subcmd> --help`

| ***Subcommand*** | *Files* | *Description* |
|---|---|---|
| `gitman users` | [*`users.sh`*](bin/users.sh) | Git user setup & basic configuration |
| `gitman repo` | [*`repo.sh`*](bin/repo.sh) | (Create,Push) remote Git repositories |
| `gitman branch` | [*`branch.sh`*](bin/branch.sh) | Create, merge, and delete branches |
| `gitman commit` | [*`commit.sh`*](bin/commit.sh) | Wrapper for git add-commit-push |
| `gitman upstream` | [*`upstream.sh`*](bin/upstream.sh) | Query upstream repositories |

### GitHub CLI (`gh`)
This is not required to *push/pull/commit/branch/etc* with **clones over *ssh***. 
* `gh` is required if you want to create repos locally and push those repos upstream.

To install the `gh-cli`, simply run the following commands.
* *Please note this is only tested on Ubuntu20.04.*
```bash
# Echo commands if '--run' omitted
gitman install-gh-cli [--run]
gh --help
``` 

## Git Authentication
#### [***SSH Key (Secure Shell)***](https://www.openssh.com/)
**Please read [***GIT-SSH.md***](/GIT-SSH.md) for details on setting up SSH w/ GitHub.**
* Running `gitman users --keygen` creates an *ssh-key-pair* and prints the *public key* to upload.
* See [**here**](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh),
 for details on adding keys to your GitHub account.
```bash
# Test setup with
ssh -T gh
```
---
#### [***PAT (Personal Access Token)***](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token).

**If you plan to use the `gh` CLI you need a *PAT*.**

That token needs the following scopes: ***repo***, ***admin:org***, and ***gist***
* Be sure to save the token (secure temporary place) as its only shown once, 
although they're easy to regenerate.
* Create one [*here*](https://github.com/settings/tokens) (must be logged in to github)
* For more details about the PAT formats, see 
[**here**](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats)

Add token to your `~/.bashrc` file with the following:
```bash
# Token should start with 'ghp_*'.
TOKEN="ghp_<new_token>"
echo "export GH_TOKEN=$TOKEN" >> ~/.bashrc

# Apply changes to current environment
source ~/.bashrc

# Test authentication
if ! gh auth status; then
    env | grep GH_TOKEN
fi

# Update $GH_TOKEN
sed [-i] "s/^export GH_TOKEN=.*$/export GH_TOKEN=$TOKEN/" ~/.bashrc
```
