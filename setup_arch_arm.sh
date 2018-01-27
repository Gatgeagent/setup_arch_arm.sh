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
echo -e "\e[36mArch Linux ARM post-installation script"
echo ""

cd /home/alarm # Just making sure we don't end up being somewhere we shouldn't be

echo -e "\e[36mChecking dependencies..."

dependOn "curl"

downloadFile "functions.sh" "https://raw.githubusercontent.com/Gatgeagent/setup_arch_arm.sh/master/functions.sh"
downloadFile "setup_arch_arm_root.sh" "https://raw.githubusercontent.com/Gatgeagent/setup_arch_arm.sh/master/setup_arch_arm_root.sh"

echo -e "\e[36mWe'll now install some things which need root permissions."

echo -e "\e[36mEnter root password \e[94m(root's password is \"\e[96mroot\e[94m\" by default)"
echo -e "\e[36mWhen you are root, type \"cd /home/alarm && bash setup_arch_arm_root.sh && exit\""
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
yaourt -S ufw ufw-extras
info_simple "Setting up ufw..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow sftp
sudo ufw enable

info "Adding admin user..."

yaourt -S adduser --noconfirm

sudo adduser admin

info "Setting up zsh for admin..."
yaourt -S zsh zsh-autosuggestions --noconfirm
sudo curl https://raw.githubusercontent.com/Gatgeagent/dotfiles/master/zshrc -o /home/admin/.zshrc
sudo curl https://raw.githubusercontent.com/Gatgeagent/dotfiles/master/nanorc -o /home/admin/.nanorc

info "Locking down ssh..."
info_simple "Enter port for ssh: "
read port || port='50'
replaceLine "/etc/ssh/sshd_config" "#Port 22" "Port $port"
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

info "Installing misc utilities..."
yaourt -S htop vtop most bzip2 vim jre9-openjdk screen tmux

info "The fingerprint of the server changed."
info "Don't forget to set \"PasswordAuthentification no\" in /etc/ssh/sshd_config!"
info "Maybe reboot the server?"