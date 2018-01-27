#!/bin/bash

# Run by root

source functions.sh
checkIfRoot()

info "Misc setup..."
pacman -Syu
curl https://raw.githubusercontent.com/Gatgeagent/dotfiles/master/nanorc -o /root/.nanorc

pacman -S wget sudo

echo "admin ALL=(ALL) ALL" > /etc/sudoers
echo "alarm ALL=(ALL) ALL" > /etc/sudoers

info "Now run the second script."

su alarm