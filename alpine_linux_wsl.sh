#!/bin/ash

# This script was written to configure Alpine Linux on WSL
# however, there is no reason it would not work in non-WSL setups
# Installation in WSL comes to ~400mb, whilst Ubuntu is ~2GB.

# Set linting rules
# shellcheck shell=ash
# shellcheck disable=SC2169

# Get username and home path. Running with sudo changes the $USER & $HOME variables to root
username=$(awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd | head -n 1)
myhome="/home/${username}"

# Check OS compatibility
if [[ -z $(command -v apk) ]]; then
  printf "apk package manager not found. Incompatible OS. exiting...\n"
  exit 1
fi

# Ensure script is running as root
if [[ "${USER}" != 'root' ]]; then
  printf "This script requires root privileges. Re-run as root user\n"
  exit 1
fi

# Check internet connection
if ! nc -zw1 google.com 443; then
  printf "No active internet connection. Check connection and try again\n"
  exit 1
fi

# System update & upgrade
apk -U upgrade

# Install applications
packages='curl git ncurses speedtest-cli sudo'
for package in $packages; do
  apk add "$package"
done

pip3 install tldr

# configure sudoers file
if ! grep -qF "${username} ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
  echo "${username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Install dotfiles
if ! grep -Fq "${myhome}/.bash_customisations" "${myhome}/.profile"; then
  cat >> "${myhome}/.profile" << EOH
# Add personal bash customisations, aliases and favourites
if [[ -f "${HOME}/.bash_customisations" ]]; then source "${HOME}/.bash_customisations"; fi
EOH
fi

dotfiles_url='https://raw.githubusercontent.com/steveharsant/dotfiles/master'
dotfiles='.bash_aliases .bash_customisations .bash_favourites .screenrc .vimrc'
for file in $dotfiles; do
    curl -sS "${dotfiles_url}/${file}" > "${myhome}/${file}"
    chown "${username}:${username}" "${myhome}/${file}"
done

printf "Don't forget to source .profile\n"
printf "You may get issues if the dotfiles are meant for bash, not ash!\n"
