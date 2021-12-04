# SSH for GitHub

==============================================================
1). Generate id\_ed25519 key pair 
 (save default, set passphrase)
	1b). ssh-keygen -t id_ed25591 -C 'github_email@mail.com'


2). Start ssh-agent in background
	2b). ssh-agent -s
	2c). eval "$(ssh-agent -s)"

3). Add private key to ssh-agent, (prompts for passphrase if key has one)
	3b). ssh-add ~/.ssh/id_ed25591


4a). Switching remotes from HTTPS to SSH
	4b). git remote -v
	4c). git remote set-url origin git@github.com:USERNAME/REPOSITORY.git
	4d). git remote -v

==============================================================
==============================================================
// Verify you have open-ssh installed, if not install it //
// Try: `command -v ssh` || `sudo apt install ssh` //
//
// Copy the following into your ~/.git/config file //
// That file most likely wont exist on your machine though //
// If thats the case, just create a blank file and copy this into it //
==============================================================
==============================================================

# See `man ssh_config` && `man sshd_config`

Host *
    ForwardAgent no
    ForwardX11 no
    ForwardX11Trusted yes
    Port 22
    Protocol 2
    VisualHostKey yes
    PreferredAuthentications publickey
    PasswordAuthentication yes
    LogLevel INFO

# Test w/ `ssh -T gh`
Host gh
    Hostname github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    # Reuse connection, persist( 1h ).
    # ControlMaster auto
    # ControlPath ~/.ssh/master-%r@%h:%p.socket
    # ControlPersist 1h

