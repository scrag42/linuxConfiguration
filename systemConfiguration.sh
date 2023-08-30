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
    DEPENDENCIES='kitty bat'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [[ $PACKAGER == "pacman" ]]; then
        if ! command_exists yay; then
            echo "Installing yay..."
            sudo ${PACKAGER} --noconfirm -S base-devel
            $(cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git && cd yay-git && makepkg --noconfirm -si)
        else
            echo "Command yay already installed"
        fi
        YAY_DEPENDENCIES='nfs-utils'
    	yay --noconfirm -S ${DEPENDENCIES} ${YAY_DEPENDENCIES}
    elif [[ $PACKAGER == "apt" ]]; then
        APT_DEPENDENCIES='nala nfs-common'
        sudo ${PACKAGER} install -yq ${DEPENDENCIES} ${APT_DEPENDENCIES}
    elif [[ $PACKAGER == "dnf" ]]; then
        DNF_DEPENDENCIES='nfs-utils'
        sudo ${PACKAGER} install -yq ${DEPENDENCIES} ${DNF_DEPENDENCIES}
    fi
}

installFlatpaks() {
	FLATHUB="com.discordapp.Discord com.brave.Browser com.spotify.Client com.github.tchx84.Flatseal com.moonlight_stream.Moonlight com.valvesoftware.Steam net.davidotek.pupgui2"
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

mountNetworkDrives() {
    if [ -e "/etc/fstab" ]; then
        read -p "Enter the IP address of the NAS: " NASIP
        SHARES="NetworkStorage SharedFiles PhotoSync"
        sudo cp /etc/fstab /etc/fstab.bak
        for share in ${SHARES}; do
            if [ -d "/mnt/${share}" ]; then
                if [ -z "$(ls -A /mnt/${share})" ]; then
                    echo "Directory /mnt/${share} is empty"
                else
                    echo -e "${RED} Directory /mnt/${share} is not empty and will not be mounted."
                    continue
                fi
            else
                sudo mkdir /mnt/${share}
            fi
            echo "${NASIP}:/mnt/user/${share} /mnt/${share} nfs vers=3,_netdev 0 0" | sudo tee -a /etc/fstab
        done
        sudo mount -a
        if [ $? -eq 0 ]; then
            echo -e "${GREEN} Network drives mounted successfully"
        else
            echo -e "${RED} Failed to mount network drives. Reverting fstab file. Please manually mount drives."
            sudo mv /etc/fstab.bak /etc/fstab
        fi
    else
        echo -e "${RED} Cannot find fstab file. Manually add network drives"
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
yesno "Do you want to mount the Network Drives? (y/n): " mountNetworkDrives
yesno "Reboot required. If kernel was updated please note that NVIDIA drivers may need reinstalled. If a blank screen occurs after reboot enter TTY (CTRL + ALT + F3) to reinstall NVIDIA driver. Reboot now? (y/n): " rebootSafe
