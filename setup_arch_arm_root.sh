#!/bin/bash

# Run by root

source /home/alarm/functions.sh
checkIfRoot

info "Updating system..."
pacman -Syu --noconfirm
info "Adding nano config..."
curl https://raw.githubusercontent.com/Gatgeagent/dotfiles/master/nanorc -o /root/.nanorc

info "Installing wget and sudo..."
pacman -S wget sudo --noconfirm

info "Giving \"admin\" and \"alarm\" sudo rights..."
echo "admin ALL=(ALL) ALL" >> /etc/sudoers
echo "alarm ALL=(ALL) ALL" >> /etc/sudoers