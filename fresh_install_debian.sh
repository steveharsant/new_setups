#!/usr/bin/env bash

# Set liniting rules
# shellcheck disable=SC2059

# Colour output variables
WHITE='\033[1;37m'
RED='\033[0;91m'
GREEN='\33[92m'
YELLOW='\033[93m'
BLUE='\033[1;34m'

FAIL=${RED}'FAIL:'${WHITE} #FAIL MESSAGES
PASS=${GREEN}'PASS:'${WHITE} #PASS MESSAGES
INFO=${YELLOW}'INFO:'${WHITE} #INFO MESSAGES
HINT=${BLUE}'HINT:'${WHITE} #HINT MESSAGES

# Get username and home path. Running with sudo changes the $USER & $HOME variables to root
USERNAME=$(awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd | head -n 1)
MYHOME="/home/${USERNAME}"

# Check OS compatibility
if [[ ! -n $(command -v apt) ]]; then
  printf "${FAIL} apt package manager not found. Incompatible OS. exiting...\n"
  exit 1
fi

# Ensure script is running as root
if [[ "${EUID}" -ne 0 ]]; then
  printf "${FAIL} This script requires root privileges. Re-run with ${YELLOW}sudo${WHITE}\n"
  exit 1
fi

# Check internet connection
if ! nc -zw1 google.com 443; then
  printf "${FAIL} No active internet connection. Check connection and try again\n"
  # exit 1
fi

# Configure sudoers file
if ! grep -qF "${USERNAME} ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Configure Nautilis address bar
sudo -u "${USERNAME}" dconf write /org/gnome/nautilus/preferences/always-use-location-entry true

# Configure external repositories
printf "${INFO} Adding external keys and repositories\n"

## Docker - NOTE: Docker installation fails for 20.04. Too new?
# curl -sSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null 2>&1

## Spotify
SPOTIFY='/etc/apt/sources.list.d/spotify.list'
if [[ ! -f ${SPOTIFY} ]]; then
  curl -sS https://download.spotify.com/debian/pubkey.gpg | apt-key add -
  echo "deb http://repository.spotify.com stable non-free" > ${SPOTIFY}
fi

## VSCodesudo cat
VSCODE='/etc/apt/sources.list.d/vscode.list'
if [[ ! -f ${VSCODE} ]]; then
  curl -sS https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > ${VSCODE}
fi

## Syncthing
SYNCTHING='/etc/apt/sources.list.d/syncthing.list'
if [[ ! -f ${SYNCTHING} ]]; then
  curl -sS https://syncthing.net/release-key.txt | sudo apt-key add -
  echo "deb https://apt.syncthing.net/ syncthing stable" > ${SYNCTHING}
fi

# Update, Upgrade and Install
printf "${INFO} Running apt update\n"
apt update -qq

printf "${INFO} Running apt upgrade\n"
apt upgrade -yqq > /dev/null 2>&1

PACKAGES=(arp-scan docker-ce docker-ce-cli code containerd.io git htop keepassxc qemu-kvm remmina speedtest-cli spotify-client syncthing tilda vim virt-manager vlc wine-stable)
for PACKAGE in "${PACKAGES[@]}"
do
  printf "${INFO} Installing ${PACKAGE}\n"
  apt install -y "${PACKAGE}" > /dev/null 2>&1
done

# Download and install dotfiles
printf "${INFO} Installing dotfiles\n"

if ! grep -Fq "${MYHOME}/.bash_customisations" "${MYHOME}/.bashrc"; then
  printf "${INFO} Updating .bashrc\n"
  cat >> "${MYHOME}/.bashrc" << EOH
   # Add personal bash customisations, aliases and favourites
   if [[ -f "${MYHOME}/.bash_customisations" ]]; then source "${MYHOME}/.bash_customisations"; fi
EOH
fi

DOTFILES_URL='https://raw.githubusercontent.com/steveharsant/dotfiles/master'
DOTFILES=(.bash_aliases .bash_customisations .bash_favourites .screenrc .vimrc)
for FILE in "${DOTFILES[@]}"; do
  printf "${INFO} Downloading latest ${FILE} from github\n"
  curl -sS "${DOTFILES_URL}/${FILE}" > "${MYHOME}/${FILE}"
done

printf "${HINT} Don't forget to source .bashrc\n"

# Download and install application config files
printf "${INFO} Installing application config files\n"

TILDA_CONFIG='~/.config/tilda/config_0'
if [[ ! -f ${TILDA_CONFIG} ]]; then
  curl -sS https://raw.githubusercontent.com/steveharsant/config_files/master/tilda_config > "${TILDA_CONFIG}"
fi

printf "Setup complete...\n"
