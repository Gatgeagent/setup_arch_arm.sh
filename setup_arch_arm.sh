#!/bin/bash

# Checks if a specific command is existent
# dependOn [command]
function dependOn() {
	if which $1 >/dev/null; then
    	echo -e "\e[32m\"$1\" is installed."
	else
    	echo -e "\e[91mThis script requires \"$1\", which is not installed."
    	exit 1
	fi
}

# Downloads a file if it doesn't already exist
# downloadFile [fileName] [url]
function downloadFile() {
	# Download file with curl, if it's not already existent
	if [ ! -f $1 ]; then
		echo -e "\e[36mDownloading \e[34m$1\e[32m..."
		curl $2 -o $1
	else
		echo -e "\e[32mDependency \e[34m$1\e[32m already satisfied."
	fi

	# Check if the file's now there
	if [ -f $1 ]; then
		echo -e "\e[32m\"$1\" was downloaded."
	else
		echo -e "\e[91mCould not download \"$1\"."
	fi
}

echo ""
echo -e "\e[36mArch Linux ARM post-installation script\e[39m"
echo ""

cd /home/alarm # Just making sure we don't end up being somewhere we shouldn't be

echo -e "\e[36mChecking dependencies...\e[39m"

dependOn "curl"

downloadFile "functions.sh" "https://raw.githubusercontent.com/Gatgeagent/setup_arch_arm.sh/master/functions.sh"
downloadFile "setup_arch_arm_root.sh" "https://raw.githubusercontent.com/Gatgeagent/setup_arch_arm.sh/master/setup_arch_arm_root.sh"
source functions.sh
info_simple "We'll now install some things which need root permissions."

info_simple "When you are root, run \"bash setup_arch_arm_root.sh && exit\""
info_simple "Enter root password \e[94m(root's password is \"\e[96mroot\e[94m\" by default)"
su root

# We're back with sudo rights now

dependOn "sudo"
source "functions.sh"

cd /home/alarm # Just making sure we don't end up being somewhere we shouldn't be

info "We will now go on and install the aur helper \"yaourt\"..."

info "Installing yaourt: Installing dependencies required to compile package-query..."
info_simple "(if you are asked for something other than the password, just press enter to use the default value)"
sudo pacman --noconfirm -S --needed base-devel git yajl

info "Installing yaourt: Cloning and installing package-query..."
git clone https://aur.archlinux.org/package-query.git
cd package-query/
makepkg -si --noconfirm
cd ..

info "Installing yaourt: Finally cloning and installing yaourt..."
git clone https://aur.archlinux.org/yaourt.git
cd yaourt/
makepkg -si --noconfirm

info "Installing yaourt: Cleaning up yaourt installation..."

cd ..
sudo rm -dR yaourt/ package-query/

info "Installing ufw..."
yaourt -S ufw ufw-extras --noconfirm
info_simple "Setting up ufw..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow sftp
sudo ufw enable

info "Adding admin user (and proper shell)..."

yaourt -S adduser zsh zsh-autosuggestions --noconfirm

sudo adduser admin

info "Setting up zsh for admin..."
sudo curl https://raw.githubusercontent.com/Gatgeagent/dotfiles/master/zshrc -o /home/admin/.zshrc
replaceLine "/home/admin/.zshrc" "export LANG=de_DE.utf8" "export LANG=en_US.utf8"
sudo curl https://raw.githubusercontent.com/Gatgeagent/dotfiles/master/nanorc -o /home/admin/.nanorc

sudo chown -R admin:users /home/admin

info "Locking down ssh..."
info_simple "Enter port for ssh: "
read port || port='50'
replaceLine "/etc/ssh/sshd_config" "#Port 22" "Port $port"
replaceLine "/etc/ssh/sshd_config" "#LoginGraceTime 2m" "LoginGraceTime 1m"
replaceLine "/etc/ssh/sshd_config" "#MaxAuthTries 6" "MaxAuthTries 3"
replaceLine "/etc/ssh/sshd_config" "#MaxSessions 10" "MaxSessions 6"
info "SSH will now run on port $port"
sudo echo "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" >> "/etc/ssh/sshd_config"
sudo echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" >> "/etc/ssh/sshd_config"
sudo echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" >> "/etc/ssh/sshd_config"
sudo echo "Protocol 2" >> "/etc/ssh/sshd_config"
sudo echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> "/etc/ssh/sshd_config"
sudo echo "HostKey /etc/ssh/ssh_host_rsa_key" >> "/etc/ssh/sshd_config"

info "Generating host keys..."

cd /etc/ssh
sudo rm ssh_host_*key*
sudo ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N "" < /dev/null
sudo ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N "" < /dev/null

sudo echo "AllowGroups ssh-user" >> "/etc/ssh/sshd_config"
sudo groupadd ssh-user
sudo usermod -a -G ssh-user root
sudo usermod -a -G ssh-user admin

info "Generating locales.."
replaceLine "/etc/locale.gen" "#en_US.UTF-8 UTF-8" "en_US.UTF-8 UTF-8"
sudo locale-gen

info "Installing misc utilities..."
yaourt -S htop vtop most bzip2 vim jdk9-openjdk screen tmux polkit --noconfirm

info "The fingerprint of the server changed."
info_simple "Don't forget to set \"PasswordAuthentification no\" in /etc/ssh/sshd_config!"
info_simple "And \"userdel alarm\""

info "By pressing enter, the server will be rebooted."
read

sudo reboot now