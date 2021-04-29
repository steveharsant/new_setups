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

version='1.0.1'
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
      -c    (Optional) Password used for any Docker containers using the \${PASSWORD} environment variable.
            An 8 character password will be generated if one is not specified.
      -d    URL to a repository containing Docker Compose .yml files.
      -h    Print this help message
      -p    git password or Personal Access Token
      -q    Quiet execution. No output messages
      -u    git username
      -v    print version
  TIP:
      Docker Compose files have a .yml file extension. .yaml files will not work\n\n"
  exit 0
}

log(){
  if [[ $quiet != 1 ]]; then
    printf "$1\n"
  fi
}

# Script arguements
while getopts "a:c:d:hp:qu:v" OPT; do
  case "$OPT" in
    a) additional_pakages=$OPTARG;;
    c) container_password=$OPTARG;;
    d) docker_compose_url=$OPTARG;;
    h) print_help;;
    p) password=$OPTARG;;
    q) quiet=1;;
    u) username=$OPTARG;;
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

# Set git user credentials if specified
if [[ -n $username ]]; then
  log 'Found credentials for repository'
  credentials="$username:$password@"
fi

# Set default repository URL if one is not specified as script argument
if [[ -z $docker_compose_url ]]; then
  docker_compose_url='https://github.com/steveharsant/Dockerfiles'
  log "Using default Dockerfile repository: $docker_compose_url"
fi

# Remove https:// prefix and .git suffix if present, get the repository
# name, then set the full url with credentials, if any
docker_compose_url=${docker_compose_url#"https://"}
docker_compose_url=${docker_compose_url%".git"}
repository_name=${docker_compose_url##*/}
docker_compose_url="https://$credentials$docker_compose_url.git"

# create directory for downloaded repository
mkdir -p /srv/scripts || :
cd /srv/scripts

# Download repository and enter directory
log 'Cloning Docker compose file repository'
git clone "$docker_compose_url" --quiet

# Generate password if left blank
if [[ -z $container_password ]]; then
  container_password="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
  printf "No password was specified. Generated password is: $container_password \n"
fi

# Create temporary .env file
echo "PASSWORD=$container_password" > /tmp/.env

log 'Running each .yml file found within the repository'
cd "./$repository_name"
files=$(find . -name "*.yml")
for file in $files
do
  docker-compose --env-file /tmp/.env up -f "$file" -d
done
