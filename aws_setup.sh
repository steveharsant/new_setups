#!/bin/bash

#Script to do basic config of an aws server based on Ubunut 16.04 server

#Update 
apt update
apt upgrade -y

#Install Applications
apt install speedtest-cli make gcc -y

#Change Hostname
rm /etc/hostname
touch /etc/hostname
echo "steve-host" >> /etc/hostname

#Update hosts file
echo "127.0.0.1 steve-host" >> /etc/hosts

#Add aliases
echo "alias xip='curl icanhazip.com'" >> ~/.bashrc

#Reload bashrc
source ~/.bashrc

#Create directories
mkdir /srv/scripts
mkdir /srv/applications

#Download scripts
cd /srv/scripts

wget https://git.io/vpn -O openvpn-install.sh #Download OpenVPN script

#Download applications
cd /srv/applications
wget http://www.no-ip.com/client/linux/noip-duc-linux.tar.gz
tar xf noip-duc-linux.tar.gz
rm noip-duc-linux.tar.gz

