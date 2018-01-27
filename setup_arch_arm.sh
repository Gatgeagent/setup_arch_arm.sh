#!/bin/bash

function downloadFile() {
	if [ ! -f $1 ]; then
		echo -e "\e[95mDownloading \e[34m$1\e[32m..."
		curl $2 -o $1
	else
		echo -e "\e[32mDependency \e[34m$1\e[32m already satisfied."
	fi
}

echo -e "\3[36Arch Linux ARM post-installation script"

downloadFile "functions.sh" ""

echo -e "\e[36mWe'll now install some things which need root permissions."

su root -c bash setup_arch_arm_root.sh