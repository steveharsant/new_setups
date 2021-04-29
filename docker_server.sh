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

version='1.3.0'

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
      -e    Comma separated key=value pairs of environment variables. (e.g. USERNAME=steve,PASSWORD=secret1234)
      -h    Print this help message
      -k    Keep generated .env file. Useful when only wanting to rerun docker-compose up -d and not the entire script.
            This will append any new environment variables specified with -e to the existing .env file
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
while getopts "a:d:e:hkqv" OPT; do
  case "$OPT" in
    a) additional_pakages=$OPTARG;;
    d) docker_compose_url=$OPTARG;;
    e) environment_variables=$OPTARG;;
    h) print_help;;
    k) keep_env_file=1;;
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

curl -sSL "$docker_compose_url" -o compose.yml

# Add environment variables to .env file
if [[ $keep_env_file != 1 ]]; then
  rm -f ./.env
fi

IFS=','
for envvar in $environment_variables; do
  echo "$envvar" >> ./.env
done

log 'Running Docker compose'
docker-compose up -d

# CLean up .env file
if [[ $keep_env_file != 1 ]]; then
  rm -f ./.env
fi
