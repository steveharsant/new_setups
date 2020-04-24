#!/bin/bash

# Wow, this is not a great script... Keeping for historical reasons.

clear
echo "
#===================================================#
#    Ubuntu 18.04 Setup and Customisation Script    #
#               Author: Steven Harsant              #
#                  Date: 19/5/2018                  #
#                   Version: 1.0                    #
#===================================================#"
#                                                   #
# This script is intended for personal use to setup #
# and customise new Ubuntu 18.04 installs. This     #
# script should be compatable with most Debian      #
# based operating systems, however it is untested.  #
#                                                   #
# A 'resources' directory is meant to acompany this #
# script for propper use. Sub directories are:      #
# -applications: Standalone applications that are   #
# copied to ~/applications                          #
# -configurations: Has sub directories for each     #
# applications configuration files. The function    #
# COPYANDCOMPARE will place these files in the      #
# correct locations. You may need to set perms      #
# -installers: package installers. Is copied to     #
# ~/applications/installers                         #
# -keys: Has 2 sub directories (public & private)   #
# These are gpg keys to be imported from their      #
# respective directories.                           #
# -scripts: scripts that are copied to /usr/bin     #
# -ssh: ssh files to be copied to ~/.ssh            #
#                                                   #
# =FUNCTIONS=                                       #
#                                                   #
# -NEWDIR:                                          #
# Creates a new directory under the user's home     #
# and sets permissions accordingly.                 #
# -COPYANDCOMPARE:                                  #
# Copies over data from the resources directory     #
# and compares the source to destination            #
# -PKGINSTALL:                                      #
# Installs a package and confirms its success       #
#                                                   #
#===================================================#
#                                                   #
#       I accept no liability. No warranty.         #
#               Use at your own risk.               #
#                                                   #
#===================================================#
echo " "

#=======================#
#                       #
# Notes and to do lists #
#                       #
#=======================#

#-Further test PKGINSTALL function as apt sometimes hangs. May need to impliment a pkill:
#-- ps aux | grep apt-get  <---grep needs to return 2+ entries
#-- pkil apt

#===========#
#           #
# Functions #
#           #
#===========#

function COPYANDCOMPARE #Copies from the resource folder to a nominated destination then compares to ensure everything was copied.
{
  DIRPATHNAME=$1
  DIRPATHDEST=$2

  printf "${INFO} Copying ${YELLOW}${DIRPATHNAME}${WHITE} from resource directory to ${YELLOW}${DIRPATHDEST}${WHITE} \n"

  if [[ -d ${RESPATH}/${DIRPATHNAME} ]]
    then

      if [[ ! -d ${DIRPATHDEST} ]]
        then
          printf "${INFO} The destination directory ${YELLOW}${DIRPATHDEST}${WHITE} does not exist. Creating directory \n"
          mkdir -p ${DIRPATHDEST}
      fi

      cp -r ${RESPATH}/${DIRPATHNAME}/* ${DIRPATHDEST}
      find ${DIRPATHDEST} -type f -exec chown $UNAME {} \;

      ISDIFF=`diff -r -q ${RESPATH}/${DIRPATHNAME} ${DIRPATHDEST} | wc -l`
      if [[ ${ISDIFF} -eq 0 ]]
        then
          printf "${PASS} All files and sub diectories in ${YELLOW}${DIRPATHNAME}${WHITE} copied successfully \n"

        else
          printf "${FAIL} Not all files and sub diectories in ${YELLOW}${DIRPATHNAME}${WHITE} copied successfully \n"
          printf "${HINT} Try and copy this directory manually with: ${YELLOW}cp -r ${RESPATH}/${DIRPATHNAME}/* ${DIRPATHDEST}${WHITE} \n"
      fi


    else
      printf "${FAIL} The ${YELLOW}${DIRPATHNAME}${WHITE} directory is not found in ${YELLOW}${RESPATH}${WHITE} \n"
  fi
}

function NEWDIR #Makes a new directory nested in the users ~ path
  {
    DIR=$1
    sudo -u $UNAME mkdir -p /home/$UNAME/$DIR

    if [ -d "/home/$UNAME/$DIR" ]
      then
        printf "${PASS} Directory${YELLOW} /home/$UNAME/$DIR ${WHITE}created successfully \n"
		   else
			  printf "${FAIL} Directory${YELLOW} /home/$UNAME/$DIR ${WHITE}failed to be created \n"
	  fi
  }

  function PKGINSTALL #Attempts install of package via apt then confirms installation state
    {
      PKG=$1
      apt-get install -qq $PKG  > /dev/null 2>&1

      PKGSTATUS=`dpkg -s ${PKG} | grep Status`

      if [[ $PKGSTATUS = "Status: install ok installed" ]]
        then
          printf "${PASS} Package${YELLOW} $PKG ${WHITE}installed successfully \n"

        else
          printf "${FAIL} Package${YELLOW} $PKG ${WHITE}failed to install \n"
      fi
    }

function FILEEXISTS
{
  FILENAME=$1
  FILEPATH=$2

  if [[ -f $FILEPATH ]]
    then
      printf "${PASS} successfully created${YELLOW} $FILENAME ${WHITE}file \n"

    else
      printf "${FAIL} Unable to create${YELLOW} $FILENAME ${WHITE}at${YELLOW} $FILEPATH ${WHITE} \n"
  fi

}

#===========================================#
#                                           #
# Set Script Environment and Perform Checks #
#                                           #
#===========================================#

#Set Colour Variables For Output#
#-------------------------------#
WHITE='\033[1;37m'
RED='\033[0;91m'
GREEN='\33[92m'
YELLOW='\033[93m'
BLUE='\033[1;34m'

FAIL=${RED}'FAIL:'${WHITE} #FAIL MESSAGES
PASS=${GREEN}'PASS:'${WHITE} #PASS MESSAGES
INFO=${YELLOW}'INFO:'${WHITE} #INFO MESSAGES
HINT=${BLUE}'HINT:'${WHITE} #HINT MESSAGES

#Check Script Is Run As root#
#---------------------------#
if [ "$EUID" -ne 0 ]
  then
    printf "${FAIL} Permission Denied \n"
    printf "${INFO} Run with the sudo command \n"
    printf "${HINT} Try the command: ${YELLOW}sudo !! ${WHITE}\n"
    exit
  else
    printf "${PASS} Script running with super user rights \n"
fi

#Check Operating System Compatability#
#------------------------------------#
OSV=`cat /etc/issue.net`

if [[ $OSV = "Ubuntu 18.04 LTS" ]]
  then
    printf "${PASS} Correct operating system found ${YELLOW} $OSV ${WHITE} \n"

  else
    printf "${FAIL} Non-compliant or non-determinable operating system found \n"
    printf "${INFO} This script is designed for ${YELLOW}Ubuntu 18.04 LTS${WHITE} \n"
    exit
fi

#Check Internet Connection#
#-------------------------#
if nc -zw1 google.com 443
  then
    printf "${PASS} Internet connection is active \n"
  else
    printf "${FAIL} Internet connection is inavtive. This script requires an internet connection. Check your connection and try agian \n"
    exit
fi

#Check Battery Status#
#--------------------#
BATS=`upower -e | grep -o BAT | wc -l` #Finds number of batteries installed
BATSTATE=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep state`; BATSTATE=`echo $BATSTATE` #Finds state of BAT0

if [[ $BATS -gt 0 ]] #Check if batteries are present
  then
    printf "${INFO} Number of batteries found${YELLOW} $BATS ${WHITE}\n"

      if [[ $BATSTATE = "state: discharging" ]] #Checks the state of the battery (Charging/Full Charged / discharging)
        then
          printf "${INFO} Battery not charging \n"

          #Calculates total charge percentage of all batteries.
          I=0; X=0
          BATS=$((BATS - 1))

          while [[ I -le $BATS ]]
            do
              BATPERCENT=`upower -i /org/freedesktop/UPower/devices/battery_BAT${I} | grep percentage`; BATPERCENT=${BATPERCENT: -3}; BATPERCENT=${BATPERCENT:: -1}
              X=$((X + BATPERCENT))
              I=$((I + 1))
          done

          BATS=$((BATS + 1)); BATPERCENT=$((X / BATS)) #Gets final percentage of battery charge amount by dividing the total charge percent by the number of batteries

          if [[ $BATPERCENT -lt 80 ]] #Checks battery charge percentage
            then
              printf "${FAIL} Battery charge must be at least ${YELLOW}80%%${WHITE} or on charge. Please connect a charger and re-run this script \n"
              exit

            else
              printf "${INFO} Battery charge above ${YELLOW}80%%${WHITE} but not charging. It is advised to connect a charger \n"
          fi

      elif [[ $BATSTATE = "state: charging" ]]
        then
          printf "${INFO} Battery charging. Do not remove power \n"

      elif [[ $BATSTATE = "state: fully charged \n" ]]
        then
          printf "${INFO} Battery at full charge \n"

      else
        printf "${FAIL} Unable to determine battery status. Ensure battery is above 80%% or on charge \n"
      fi

  else
    printf "${INFO} No installed batteries found \n"
fi

#Set Script Path#
#---------------#
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
printf "${INFO} Script path set to${YELLOW} $SCRIPTPATH ${WHITE} \n"

#Check Resources Exist#
#---------------------#
RESPATH="${SCRIPTPATH}/resources"

if [ -d $RESPATH ]
  then
    printf "${PASS} Found resources path \n"

  else
    printf "${FAIL} Resources directory  not found  \n"
    printf "${INFO} Ensure path is set to${YELLOW} $RESPATH ${WHITE}\n"
    exit
fi

#Get Logged In User And Set $UNAME Variable#
#------------------------------------------#
UNAME=`awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd | head -n 1`

#Confirm Username#
#----------------#
printf "${INFO} The currently logged in user is${YELLOW} $UNAME ${WHITE} \n"
while true; do
    read -p "Continue [y/n]?" YN
    case $YN in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no";;
    esac
done

#Set Hostname#
#------------#
read -p "Set hostname: " HOST
printf "${INFO} Hostname set to${YELLOW} $HOST ${WHITE} \n"

#=====================#
#                     #
# Basic Configuration #
#                     #
#=====================#

#Create User Folders#
#-------------------#
NEWDIR applications
NEWDIR .aws
NEWDIR Downloads/.sysaid
NEWDIR iso_images
NEWDIR scripts/bash
NEWDIR scripts/clients
NEWDIR scripts/cmd
NEWDIR drive/personal
NEWDIR scripts/powershell
NEWDIR drive/team

#System Configuration#
#--------------------#

#Set hostname
rm /etc/hostname
touch /etc/hostname
echo $HOST >> /etc/hostname

CHKHOST=`cat /etc/hostname`
if [[ $CHKHOST = "$HOST" ]]
  then
    printf "${PASS} Hostname set successfully to ${YELLOW} $HOST ${WHITE} \n"

 else
    printf "${FAIL} Hostname failed to be set \n"

    if [[ -f /etc/hostname ]] #Confirm hostname file exists.
      then
        printf "${INFO} Hostname file ${YELLOW}/etc/hostname${WHITE} exists. \n"
        printf "${HINT} Manually add hostname to the ${YELLOW}/etc/hostname${WHITE} file \n"

      else
        printf "${FAIL} Hostname file ${YELLOW}/etc/hostname${WHITE} does not exist \n"
        printf "${HINT} Use the command ${YELLOW}sudo touch /etc/hostname${WHITE} to create the hostname file \n"
    fi

fi

#Update hosts File
if [[ -f /etc/hosts ]]
  then
    printf "${INFO} Hosts file ${YELLOW}/etc/hosts${WHITE} exists \n"
    echo "127.0.0.1 $HOST" >> /etc/hosts

    CHKHOST=`cat /etc/hosts | tail -1`
    if [[ $CHKHOST = "127.0.0.1 $HOST" ]]
      then
        printf "${PASS} Hosts file successfully updated with ${YELLOW}127.0.0.1 $HOST ${WHITE} \n"

      else
        printf "${FAIL} Unable to update hosts file \n"
        printf "${HINT} Manually update hosts file to include ${YELLOW}127.0.0.1 $HOST ${WHITE} \n"
    fi

  else
    printf "${FAIL} Hosts file ${YELLOW}/etc/hosts${WHITE} does not exist \n"
    printf "${INFO} Attempting to create hosts file \n"

cat > /etc/hosts << EOL
127.0.0.1	localhost
127.0.1.1	$HOST

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.0.1 $HOST
EOL

      if [[ -f /etc/hosts ]]
        then
          printf "${PASS} Hosts file created successfully \n"

        else
          printf "${FAIL} Unable to create hosts file \n"
          printf "${HINT} Use the command ${YELLOW}sudo touch /etc/hosts${WHITE} to create the hosts file and add the below entries \n"

echo "127.0.0.1	localhost
127.0.1.1	$HOST

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.0.1 $HOST"

      fi
fi

#Bash Configuration#
#------------------#

#Set /etc/sudoers Configuration
printf "${INFO} Setting sudoers file configuration \n"

if grep -qF "$UNAME ALL=(ALL) NOPASSWD: ALL" /etc/sudoers
  then
    printf "${INFO} User${YELLOW} $UNAME ${WHITE}already has configuration set in sudoers file \n"
  else
    echo "$UNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    printf "${PASS} User${YELLOW} $UNAME ${WHITE} has been configured in the sudoers file \n"

fi

#Add .bash_aliases File
if [[ -f /home/$UNAME/.bash_aliases ]]
  then
  printf "${INFO} The .bash_aliases file at ${YELLOW}/home/$UNAME/.bash_aliases${WHITE} already exists \n"

  else
  touch /home/$UNAME/.bash_aliases
  printf "${PASS} Created ${YELLOW}.bash_aliases${WHITE} file \n"
fi

BAOWNER=`stat -c '%U' /home/$UNAME/.bash_aliases`
if [[ $BAOWNER = $UNAME ]]
  then
    printf "${PASS} Correct owner permissions already set on ${YELLOW}.bash_aliases${WHITE} file \n"
  else
    chown $UNAME -v /home/$UNAME/.bash_aliases > /dev/null 2>&1
    printf "${PASS} Owner set to ${YELLOW}.bash_aliases${WHITE} file \n"
fi

#Add Aliases
cat > /home/$UNAME/.bash_aliases << EOL
alias xip='curl icanhazip.com'
alias wdns='nmcli device show wlp4s0 | grep IP4.DNS'
alias ldns='nmcli device show enp0s31f6 | grep IP4.DNS'
alias topdir='echo Drive Space Usage && echo ================= && echo && sudo du -Sh --exclude=./proc --exclude=./run --exclude=./home/.ecryptfs | sort -rh | head -25'
alias repos='grep -h ^deb /etc/apt/sources.list /etc/apt/sources.list.d/*'
alias sudp='sudo'
EOL

#Reload bashrc
source /home/$UNAME/.bashrc

#Create and Configure cron Jobs#
#------------------------------#
cat > /etc/cron.weekly/clean_sysaid_downloads.sh << EOL
#!/bin/bash
rm /home/$UNAME/Downloads/.sysaid/*
EOL

if [ -e /etc/cron.weekly/clean_sysaid_downloads.sh ]
  then
    printf "${PASS} ${YELLOW}Weekly${WHITE} cron job set to clean ${YELLOW}/home/$UNAME/Downloads/.sysaid/${WHITE} directory \n"

  else
    printf "${FAIL} Failed to create cron job at ${YELLOW}/etc/cron.weekly/clean_sysaid_downloads.sh {$WHITE} \n"
fi

#======================#
# 			               #
# Install Applications #
# 	                   #
#======================#

#Keys#
#----#
printf "${INFO} Adding public keys for apt \n"

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - > /dev/null 2>&1 #Chrome Web Browser
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C  > /dev/null 2>&1 #insync gDrive File Sync Tool
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410  > /dev/null 2>&1 #Spotify Music Player

#Repositories#
#------------#
printf "${INFO} Adding package repositories \n"

add-apt-repository -y ppa:webupd8team/atom > /dev/null 2>&1 #Atom Text Editor
add-apt-repository -y ppa:ubuntubudgie/backports > /dev/null 2>&1  #Budgie Backports Repo For Applets
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null 2>&1 #chrome Web Browser
echo "deb http://apt.insynchq.com/ubuntu bionic non-free contrib" | tee /etc/apt/sources.list.d/insync.list > /dev/null 2>&1 #Insync gDrive File Sync Tool
echo deb http://repository.spotify.com stable non-free | tee /etc/apt/sources.list.d/spotify.list > /dev/null 2>&1 #Spotify Music Player
add-apt-repository -y ppa:atareao/atareao > /dev/null 2>&1 #Touchpad Indicator Tool

#Repositories & System Update#
#----------------------------#
printf "${INFO} Running apt update \n"
apt-get update -qq

printf "${INFO} Running apt upgrade \n"
apt-get upgrade -qq > /dev/null 2>&1

#Install Desktop Environment#
#---------------------------#
PKGINSTALL arc-theme
PKGINSTALL budgie-calendar-applet
PKGINSTALL budgie-core budgie-dropby-applet
PKGINSTALL budgie-indicator-applet
PKGINSTALL budgie-screenshot-applet
PKGINSTALL budgie-showtime-applet
PKGINSTALL budgie-weather-applet
PKGINSTALL plymouth-theme-ubuntu-budgie-logo
PKGINSTALL pocillo-icon-theme

#Install Applications#
#--------------------#
PKGINSTALL atom
PKGINSTALL arp-scan
PKGINSTALL autokey-gtk
PKGINSTALL chromium-browser
PKGINSTALL curl
PKGINSTALL default-jre
PKGINSTALL gcc
PKGINSTALL git
PKGINSTALL google-chrome-stable
PKGINSTALL gparted
PKGINSTALL insync
PKGINSTALL libvirt-bin
PKGINSTALL make
PKGINSTALL net-tools
PKGINSTALL pwgen
PKGINSTALL qemu-kvm
PKGINSTALL remmina
PKGINSTALL speedtest-cli
PKGINSTALL spotify-client
PKGINSTALL sshuttle
PKGINSTALL subnetcalc
PKGINSTALL tilda
PKGINSTALL touchpad-indicator
PKGINSTALL vim
PKGINSTALL virt-manager
PKGINSTALL vlc
PKGINSTALL wine-stable

#========================#
#                        #
# Configure Applications #
#                        #
#========================#

#Copy from Resources Directory#
#-----------------------------#
COPYANDCOMPARE applications /home/$UNAME/applications
COPYANDCOMPARE installers /home/$UNAME/applications/installers
COPYANDCOMPARE ssh /home/$UNAME/.ssh

#Set Permissions#
chown $UNNAME home/$UNAME/applications/
chown $UNNAME home/$UNAME/applications/bomgar_auto_elevation

#Configure Autostart Applications#
#--------------------------------#
NEWDIR .config/autostart
COPYANDCOMPARE "configurations/autostart" "/home/$UNAME/.config/autostart"
find /home/$UNAME/.config/autostart -type f -exec chmod 664 {} \; > /dev/null 2>&1

#Configure Application Environments#
#----------------------------------#

#Configure AutoKey Responses
printf "${INFO} Setting Canned Responses for AutoKey \n"
NEWDIR .config/autokey/data/CannedResponses
COPYANDCOMPARE "configurations/autokey/CannedResponses" "/home/$UNAME/.config/autokey/data/CannedResponse"
printf "${INFO} Copying AutoKey configuration files"
COPYANDCOMPARE "configurations/autokey/configurations" "/usr/lib/python2.7/dist-packages/autokey/gtkui/data/"

#Configure Nautilis Settings
printf "${INFO} Setting configuration for Nautilis \n"
sudo -u $UNAME dconf write /org/gnome/nautilus/preferences/always-use-location-entry true

#Download and Symlink Scripts
printf "${INFO} Downloading and configuring scripts \n"

curl -s https://raw.githubusercontent.com/alexanderepstein/Bash-Snippets/master/cheat/cheat >> /home/$UNAME/scripts/bash/cheat.sh
chmod +x /home/$UNAME/scripts/bash/cheat.sh
ln -sf /home/$UNAME/scripts/bash/cheat.sh /usr/bin/cheat
FILEEXISTS "cheat script" "/home/$UNAME/scripts/bash/cheat.sh"

curl -s https://raw.githubusercontent.com/steveharsant/misc_scripts/master/batstat.sh >> /home/$UNAME/scripts/bash/batstat.sh
chmod +x /home/$UNAME/scripts/bash/batstat.sh
ln -sf /home/$UNAME/scripts/bash/batstat.sh /usr/bin/batstat
FILEEXISTS "batstat script" "/home/$UNAME/scripts/bash/batstat.sh"

#Copy scripts from resources directory
cp ${RESPATH}/scripts/passes /home/$UNAME/scripts/bash/passes.sh
ln -sf /home/$UNAME/scripts/bash/passes.sh /usr/bin/passes
FILEEXISTS "passes script" "/home/$UNAME/scripts/bash/passes.sh"
printf "${INFO} Setting permissions on ${YELLOW}passes script${WHITE} \n"
chmod 755 /usr/bin/passes
printf "${HINT} Manual editing of the passes script found at ${YELLOW}/home/$UNAME/scripts/bash/passes.sh${WHITE} still needs to be completed \n"

cp ${RESPATH}/scripts/sshvpn /home/$UNAME/scripts/bash/sshvpn.sh
ln -sf /home/$UNAME/scripts/bash/sshvpn.sh /usr/bin/sshvpn
printf "${INFO} Setting permissions on ${YELLOW}sshvpn script${WHITE} \n"
chmod 755 /usr/bin/sshvpn
FILEEXISTS "sshvpn script" "/home/$UNAME/scripts/bash/sshvpn.sh"

#Configure tilda Environment
printf "${INFO} Configuring Tilda environment \n"
NEWDIR .config/tilda
COPYANDCOMPARE "configurations/tilda" "/home/$UNAME/.config/tilda/"

#Configure touchpad-indicator Environments
printf "${INFO} Configuring touchpad indicator environment \n"
NEWDIR .config/touchpad-indicator
COPYANDCOMPARE "configurations/touchpad-indicator" "/home/$UNAME/.config/touchpad-indicator/"

#Congfigure vim Environment
printf "${INFO} Configuring vim environment \n"
echo "set number" >> /home/$UNAME/.vimrc
echo "syntax on" >> /home/$UNAME/.vimrc
FILEEXISTS "vim configuration" "/home/$UNAME/.vimrc"

#Set permissions on ksuperkey
chmod +x /home/$UNAME/applications/ksuperkey
printf "${INFO} Execute permissions set for ${YELLOW}ksuperkey${WHITE} \n"
printf "${HINT} For ${YELLOW}ksuperkey${WHITE} to be useful, ensure ${YELLOW}Cerebro${WHITE} is installed and configured to use ${YELLOW}ALT+F1${WHITE} as its shortcut keys\n"

#Install Plugins#
#---------------#

#Install vim GPG Plugin
printf "${INFO} Downloading and installing gnupg plugin for vim \n"
NEWDIR .vim/plugin
curl -s https://raw.githubusercontent.com/jamessan/vim-gnupg/master/plugin/gnupg.vim >> /home/$UNAME/.vim/plugin/gnupg.vim
FILEEXISTS "gnuPG plugin" "/home/$UNAME/.vim/plugin/gnupg.vim"

#=================#
#                 #
# Import GPG Keys #
#                 #
#=================#

#Set Permissions on .gnugp Directory#
#-----------------------------------#
NEWDIR .gnupg
#sudo chown -R $UNAME /home/$UNAME/.gnupg

#Import Private Key#
#------------------#
if [[ -d ${RESPATH}/keys/private ]]
  then
    FILES=${RESPATH}/keys/private/*

    for F in $FILES
      do
	      KEYNAME=`echo ${F} | sed -e 's/\/.*\///g'`
        printf "${INFO} Importing private key: ${YELLOW}${KEYNAME}${WHITE} \n"
        sudo -u $UNAME gpg --import $F > /dev/null 2>&1
      done
  else
    printf "${FAIL} No private key directory found in ${YELLOW}${RESPATH}/keys${WHITE} \n"
fi


#Import Public Keys#
#------------------#
if [[ -d ${RESPATH}/keys/public ]]
  then
    FILES=${RESPATH}/keys/public/*

    for F in $FILES
      do
	      KEYNAME=`echo ${F} | sed -e 's/\/.*\///g'`
        printf "${INFO} Importing public key: ${YELLOW}${KEYNAME}${WHITE} \n"
	      sudo -u $UNAME gpg --import $F > /dev/null 2>&1
      done
  else
    printf "${FAIL} No public key directory found in ${YELLOW}${RESPATH}/keys${WHITE} \n" > /dev/null 2>&1
fi

#########################
#                       #
# END OF SCRIPT PROMPTS #
#                       #
#########################

printf "${INFO} setup complete. It is recommended to restart \n"
while true; do
    read -p "Restart [y/n]?" YN
    case $YN in
        [Yy]* ) init 6;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no";;
    esac
done
