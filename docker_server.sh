#!/usr/bin/env bash

# A very simple script to configure a Docker server.
# It has the ability to pull a repository of Dockerfiles
# to execute them sequentially.

# Set linting rules
# shellcheck disable=SC1090
# shellcheck disable=SC2002
# shellcheck disable=SC2059
# shellcheck disable=SC2086
# shellcheck disable=SC2164

version='1.1.0'

# Functions
print_help(){
  printf "Docker Server Setup and Container Deploy Script\n
  version: $version \n
  This is a very simple script to configure a Debian based Docker server.\n
  It installs a predefined list of tools as well as taking a repository of
  Docker Compose .yml files and executes each .yml file to spin up n containers.\n
  USAGE:
      docker_server.sh
  OPTIONS:
      -a    space seperated list of additional packages to install via apt
      -d    URL to a repository containing Docker Compose .yml files.
      -h    Print this help message
      -p    (Optional) Password used for any Docker containers using the \${PASSWORD} environment variable.
            An 8 character password will be generated if one is not specified.
      -q    Quiet execution. No output messages
      -v    print version \n\n"
  exit 0
}

log(){
  if [[ $quiet != 1 ]]; then
    printf "$1\n"
  fi
}

# Script arguements
while getopts "a:d:hp:qv" OPT; do
  case "$OPT" in
    a) additional_pakages=$OPTARG;;
    d) docker_compose_url=$OPTARG;;
    h) print_help;;
    p) container_password=$OPTARG;;
    q) quiet=1;;
    v) printf "$version\n";;
    *) printf "Invalid argument passed -$OPT.\n" && exit 1 ;;
  esac
done

#
# System updates and package installation
#

log 'Running apt update'
apt update -qq

log 'Running apt upgrade'
apt upgrade -yqq -o Dpkg::Options::=--force-confdef > /dev/null 2>&1

log 'Removing any old Docker components'
apt remove docker docker-engine docker.io containerd runc > /dev/null 2>&1

packages="apt-transport-https ca-certificates curl git gnupg htop jq lsb-release speedtest-cli vim $additional_pakages"

log "Installing the following packages: $packages"
apt install -y -o Dpkg::Options::=--force-confdef "$packages" > /dev/null 2>&1

# Install Docker compose
log 'Installing Docker compose'
curl -sSL "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

# Install command completion
curl -sSL "https://raw.githubusercontent.com/docker/compose/1.29.1/contrib/completion/bash/docker-compose" \
  -o /etc/bash_completion.d/docker-compose

#
# Download and execute Docker compose files in specified repository
#

# Exit if no compose file is given
if [[ -z $docker_compose_url ]]; then
  log 'No URL to Docker Compose .yml file. exiting'
  exit 0
fi

mkdir /srv/scripts
cd /srv/scripts
curl -sSL "$docker_compose_url" -o compose.yml

# Generate password if left blank
if [[ -z $container_password ]]; then
  container_password="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
  printf "No password was specified. Generated password is: $container_password \n"
fi

# Create temporary .env file
echo "PASSWORD=$container_password" > ./.env

log 'Running Docker compose'
docker-compose up -d
