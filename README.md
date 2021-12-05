# gitbash
*Wrapper for Git on Ubuntu-20.04.*

## Setup
> *Shell expansion results in the following equalities, but please also note the non-equality.*
> 
> *( ~/bin == /$HOME/bin == /home/$USER/bin ) != ( /usr/bin )*
> > * ~/bin - executables **only** ***$USER*** has privileges to run
> > * /usr/bin - **shared** executables on ***$HOSTNAME***
---
**Ideally create *~/bin* if it doesn't exist.**
* By logging out then logging back on ***~/bin*** will added to your ***$PATH*** variable.
```bash
mkdir ~/bin
exit
<login>
```
 
> See [***here***](https://askubuntu.com/questions/60218/how-to-add-a-directory-to-the-path) 
> for setting custom directories on your ***$PATH*** and the `man bash` excerpt below.
> ```txt
>  PATH   
>    The search path for commands. It is a colon-separated list of directories 
>    in which the shell looks for commands (see COMMAND EXECUTION below). 
>    A zero-length (null) directory name in the value of PATH indicates the current directory. 
>    A null directory name may appear as two adjacent colons, or as an initial or trailing colon.   
>    The default path is system-dependent, and is set by the administrator who installs bash.  
>    A common value is ``/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin''.

**To verify your *$PATH* has been updated with */home/$USER/bin* run the command below**
* Your full ***$PATH*** variable should be returned, otherwise `grep` exits on error.
```bash
env | grep "^PATH=.*:$HOME/bin:.*$"
```
---
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
---
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
*Only required when working with **remote** "github.com" repositories*

To install the `gh-cli`, simply run the following commands.
* *Please note this is only tested on Ubuntu20.04.*
```bash
# Echo commands when '--run' flag is omitted.
gitman install-gh-cli [--run]
gh --help
``` 
---
## GitHub CLI Authentication
* Only one of the following is **required** but *both can exist simultaneously* on the same machine.

#### [***SSH Key (Secure Shell)***](https://www.openssh.com/)
**Please read [***GIT-SSH.md***](/GIT-SSH.md) for details on configuring SSH on your host.**
* Running `gitman users --keygen` creates an *ssh-key-pair* and prints the *public key* to upload.
* See [**here**](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh),
 for details on adding keys to your GitHub account.
```bash
# Test setup with
ssh -T gh
```
---
#### [***PAT (Personal Access Token)***](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
If you plan to use **remote connections** over ***HTTPS***, you will need a ***PAT***.
* For more details about the PAT formats, see 
[**here**](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github#githubs-token-formats)

Create a token [*here*](https://github.com/settings/tokens) (must be logged in to github account)
* You will need to give that token the following scopes: 
  * ***repo, admin:org, and gist***
* Be sure to save the token (secure temporary place) as its only shown once.
* If it is lost just create another token and delete the previous references on `gh` and in *~/.bashrc*

Add token to your `~/.bashrc` file with the following:
```bash
# Token should start with 'ghp_*'.
TOKEN="ghp_<new_token>"

if ! grep 'GH_TOKEN' ~/.bashrc; then
    echo "GH_TOKEN=$TOKEN" >> ~/.bashrc
else
    sed [-i] "s/^GH_TOKEN=.*$/GH_TOKEN=$TOKEN/" ~/.bashrc
fi

source ~/.bashrc
```
