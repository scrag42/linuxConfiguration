#!/bin/bash

RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'

setEnv() {
    GITPATH="$(dirname "$(realpath "$0")")"

    PACKAGEMANAGER='apt dnf pacman'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo -e "Using ${pgm}"
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager"
        exit 1
    fi
}

command_exists () {
    command -v $1 >/dev/null 2>&1;
}

installPackages() {
    ## Check for dependencies.
    DEPENDENCIES='kitty'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [[ $PACKAGER == "pacman" ]]; then
        sudo pacman -S nfs-utils timeshift ${DEPENDENCIES} --noconfirm
    elif [[ $PACKAGER == "apt" ]]; then
        APT_DEPENDENCIES='nala nfs-common'
        sudo ${PACKAGER} install -yq ${DEPENDENCIES} ${APT_DEPENDENCIES}
    elif [[ $PACKAGER == "dnf" ]]; then
        DNF_DEPENDENCIES='nfs-utils'
        sudo ${PACKAGER} install -yq ${DEPENDENCIES} ${DNF_DEPENDENCIES}
    fi
}

# net.davidotek.pupgui2 is ProtonUp-Qt
installFlatpaks() {
	FLATHUB="com.discordapp.Discord com.spotify.Client com.github.tchx84.Flatseal com.moonlight_stream.Moonlight com.valvesoftware.Steam net.davidotek.pupgui2"
	if ! command_exists flatpak; then
        	echo -e "${YELLOW}Flatpak not installed. Installing Flatpak..."
	 	if [[ $PACKAGER == "pacman" ]]; then
        		sudo ${PACKAGER} --noconfirm install flatpak
	  	else
    			sudo ${PACKAGER} install -yq flatpak
       		fi
   	fi
    	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	flatpak install -y flathub ${FLATHUB}
}

configureKitty() {
    if [ -e "${HOME}/.config/kitty/kitty.conf" ]; then
        mv ${HOME}/.config/kitty/kitty.conf ${HOME}/.config/kitty/kitty.conf.bak
        cp ${GITPATH}/kitty.conf ${HOME}/.config/kitty/kitty.conf
    else
        echo -e "${RED} Cannot find kitty config file."
    fi
}

yesno() {
    read -p "$1" answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        $2
    elif [[ $answer == "n" || $answer == "N" ]]; then
        echo -e "${Yellow} Skipping step..."
    else
        yesno "$1" "$2" 
    fi
}

installSid() {
    if [[ $(cat /etc/os-release | grep -w ID) == *"debian"* ]]; then
        echo -e "${YELLOW} Debian system detected. Updating to Sid can provide better hardware support for newer hardware and updated packages. Please note that this may break your system, speicifally NVIDIA drivers if a new kernel is installed. Please backup your system before continuing."
        yesno "Do you want to install Sid? (y/n): " updateAptSources
        sudo apt update && sudo apt upgrade -y
    else
        echo -e "${YELLOW} Not Debian. Skipping step..."
    fi
}

updateAptSources() {
    echo "deb http://deb.debian.org/debian/ sid main non-free-firmware contrib non-free" | sudo tee /etc/apt/sources.list
    echo "deb-src http://deb.debian.org/debian/ sid main non-free-firmware contrib non-free" | sudo tee -a /etc/apt/sources.list
}

rebootSafe() {
    echo -e "${GREEN} Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
}

setEnv
installSid
installPackages
installFlatpaks
configureKitty
yesno "Reboot required. If kernel was updated please note that NVIDIA drivers may need reinstalled. If a blank screen occurs after reboot enter TTY (CTRL + ALT + F3) to reinstall NVIDIA driver. Reboot now? (y/n): " rebootSafe
