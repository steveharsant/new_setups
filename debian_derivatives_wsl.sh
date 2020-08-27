#!/usr/bin/env bash
#
# v 1.0.0
#
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
if [[ -z $(command -v apt) ]]; then
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
  exit 1
fi

# Configure sudoers file
if ! grep -qF "${USERNAME} ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi


# Install apt-transport-https and curl to allow repos to be populated correctly
apt install -y -o Dpkg::Options::=--force-confdef apt-transport-https curl -y

# Configure external repositories
printf "${INFO} Adding external keys and repositories\n"

# Update, Upgrade and Install
printf "${INFO} Running apt update\n"
apt update -qq

printf "${INFO} Running apt upgrade\n"
apt upgrade -yqq > /dev/null 2>&1

PACKAGES=(arp-scan git htop python3-pip speedtest-cli tldr vim)

for PACKAGE in "${PACKAGES[@]}"
do
  printf "${INFO} Installing ${PACKAGE}\n"
  apt install -y -o Dpkg::Options::=--force-confdef "${PACKAGE}" > /dev/null 2>&1
done

# apt cleanup
printf "${INFO} Running apt autoremove\n"
apt autoremove -y > /dev/null 2>&1

# Install python venv
pip3 install virtualenv > /dev/null 2>&1

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
  chown "${USERNAME}:${USERNAME}" "${MYHOME}/${FILE}"
done

printf "${HINT} Don't forget to source .bashrc\n"

printf "Setup complete...\n"
