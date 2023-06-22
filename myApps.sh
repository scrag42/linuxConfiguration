#!/bin/bash

command_exists () {
    command -v $1 >/dev/null 2>&1;
}

installPackages() {
    ## Check for dependencies.
    DEPENDENCIES='kitty bat gnome-tweaks'
    echo -e "${YELLOW}Installing dependencies...${RC}"
    if [[ $PACKAGER == "pacman" ]]; then
        if ! command_exists yay; then
            echo "Installing yay..."
            sudo ${PACKAGER} --noconfirm -S base-devel
            $(cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R ${USER}:${USER} ./yay-git && cd yay-git && makepkg --noconfirm -si)
        else
            echo "Command yay already installed"
        fi
    	yay --noconfirm -S ${DEPENDENCIES}
    else 
    	sudo ${PACKAGER} install -yq ${DEPENDENCIES}
    fi
}

installFlatpaks() {
	FLATHUB="com.visualstudio.code com.discordapp.Discord com.brave.Browser com.spotify.Client com.github.tchx84.Flatseal com.parsecgaming.parsec com.valvesoftware.Steam net.davidotek.pupgui2"
	if ! command_exists flatpak; then
        	echo -e "${RED}To run me, you need: flatpak"
        	exit 1
    	fi
	flatpak install -y flathub ${FLATHUB}
}

installPackages
installFlatpaks
