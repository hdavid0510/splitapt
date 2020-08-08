#!/bin/bash

# Constants
FONT_RESET='\e[0m'
FONT_BLACK='\e[30m'
FONT_YELLOW='\e[93m'
FONT_MAGENTA='\e[95m'
FONT_CYAN='\e[96m'
FONT_BACK_YELLOW='\e[103m'
FONT_BOLD='\e[1m'
REGEX_NUMONLY='^[0-9]+$'

ARCH=$(uname -a)
if [[ "${ARCH}" == "x86_64" || "${ARCH}" == "x86" ]]; then
	APT='apt-fast' #apt-fast only supports amd64 and i386.
else
	APT='apt'
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
UPKG_LIST_ALL="${DIR}/.upkg_list.txt"
UPKG_LISTS_READY="${DIR}/.upkg_lists_ready"
UPKG_LISTS_DONE="${DIR}/.upkg_lists_done"




###########################################################################
############################  SETUP MODULE  ###############################
###########################################################################

# Title
#clear
echo -e "\n${FONT_BOLD}${FONT_BACK_YELLOW}${FONT_BLACK}           APT SPLIT UPGRADER   v0.5          ${FONT_RESET}"
echo -e "${FONT_BACK_YELLOW}${FONT_BLACK}    upgrade package list preparation module   ${FONT_RESET}\n\n"



# Prepare directories
echo -e "\n${FONT_CYAN}${FONT_BOLD}[1/7]${FONT_RESET}${FONT_YELLOW} Preparing directories...${FONT_RESET}"
echo -e "Preparing list file : ${UPKG_LIST_ALL}"
rm -f ${UPKG_LIST_ALL}
echo -e "Preparing folder for splitted lists : ${UPKG_LISTS_READY}"
rm -rf ${UPKG_LISTS_READY}
mkdir ${UPKG_LISTS_READY}
echo -e "Preparing folder for processed lists : ${UPKG_LISTS_DONE}"
rm -rf ${UPKG_LISTS_DONE}
mkdir ${UPKG_LISTS_DONE}
sleep 1


# Preparing for getting list
echo -e "\n${FONT_CYAN}${FONT_BOLD}[2/7]${FONT_RESET}${FONT_YELLOW} Preparing required APT softwares${FONT_RESET}"
# Need to check if apt is locked, not working
sudo dpkg --configure -a
sudo apt install aptitude -y --show-progress
sync
sleep 1


# Get list
echo -e "\n${FONT_CYAN}${FONT_BOLD}[3/7]${FONT_RESET}${FONT_YELLOW} Get upgrade list via aptitude${FONT_RESET}"
sudo apt update
sudo apt list --upgradable
# echo -e -n "${FONT_MAGENTA}\nProceed upgrading? [y/n] ${FONT_RESET}"
# read CONFIRM_ANS
# if [[ "${CONFIRM_ANS}" == "y" || "${CONFIRM_ANS}" = "Y" || "${CONFIRM_ANS}" == "" ]]; then
# 	echo -e "${FONT_MAGENTAF}etching update to file...${FONT_RESET}"
# else
# 	echo -e "${FONT_MAGENTAEXITING} WITH ERROR -1 : USER REQUESTED${FONT_RESET}"
# 	exit -1
# fi

aptitude search -F "%p" --disable-columns "~U" >> ${UPKG_LIST_ALL}
echo -e "\n${FONT_YELLOW} List file saved! ${FONT_RESET}"
sync
sleep 3


# Line split into files
echo -e "\n${FONT_CYAN}${FONT_BOLD}[4/7]${FONT_RESET}${FONT_YELLOW} Split list files.${FONT_RESET}"
while true; do
	echo -e -n "${FONT_MAGENTA} Number of packages per file : ${FONT_RESET}"
	read SPLIT_LINE
	if [[ ${SPLIT_LINE} =~ $REGEX_NUMONLY ]] ; then
		echo -e -n "${SPLIT_LINE} ${FONT_MAGENTA}packages(s), correct? [y/n] ${FONT_RESET}"
		read CONFIRM_ANS
		case "${CONFIRM_ANS}" in
			[yY]) break ;;
		esac
	fi
done
split -l ${SPLIT_LINE} ${UPKG_LIST_ALL} ${UPKG_LISTS_READY}/
echo -e "${FONT_YELLOW} Files generated : ${FONT_RESET}"
ls ${UPKG_LISTS_READY}
sync
sleep 3


# Started. APT Preparation
echo -e "\n${FONT_CYAN}${FONT_BOLD}[5/7]${FONT_RESET}${FONT_YELLOW} Check depencency ${FONT_RESET}"
sudo apt install -f -y
sudo apt autoremove -y
sync
sleep 1


# Cache clean
echo -e "\n${FONT_CYAN}${FONT_BOLD}[6/7]${FONT_RESET}${FONT_YELLOW} Clean apt cache ${FONT_RESET}"
if [[ "${APT}" == "apt-fast" ]]; then
	sudo rm -rf /var/cache/apt/archives/apt-fast
fi
sudo apt clean
sync
sleep 1


# APT-FAST check
echo -e "\n${FONT_CYAN}${FONT_BOLD}[7/7]${FONT_RESET}${FONT_YELLOW} Check essential utilities installed ${FONT_RESET}"
sudo apt install ${APT} nano -y --show-progress
sync
sleep 1


# Start install module!
echo -e "\n${FONT_CYAN}${FONT_BOLD} Preparation done! ${FONT_RESET}"
sync
sleep 1




###########################################################################
##########################  INSTALLER MODULE  #############################
###########################################################################

# Title
#clear
echo -e "\n${FONT_BOLD}${FONT_BACK_YELLOW}${FONT_BLACK}           APT SPLIT UPGRADER   v0.5          ${FONT_RESET}"
echo -e "${FONT_BACK_YELLOW}${FONT_BLACK}            package upgrade module            ${FONT_RESET}\n\n"


# List read preparation
LIST_INDEX_MAX=$(ls ${UPKG_LISTS_READY} -l | grep -v ^l | wc -l)
LIST_INDEX_MAX=$((LIST_INDEX_MAX-1))


# Get sleep duration
while true
do
	echo -e -n "${FONT_MAGENTA}Sleep time secs between files [0~60 seconds] ${FONT_RESET}"
	read DELAY_TIME
	if [[ ${DELAY_TIME} =~ ${REGEX_NUMONLY} ]] ; then
		if (( ${DELAY_TIME} >= 0 || ${DELAY_TIME} <= 120 )) ; then
			echo -e -n "${DELAY_TIME} ${FONT_MAGENTA}seconds(s): Proceed? [y/n] ${FONT_RESET}"
			read CONFIRM_ANS
			case "${CONFIRM_ANS}" in
				[yY]) break ;;
				*) echo continue ;;
			esac
		fi
	fi
done


# INSTALL PACKAGES!
LIST_INDEX_NOW=0
for UPKG_LIST_NOW in ${UPKG_LISTS_READY}/* ; do
	echo -e "${FONT_CYAN}${FONT_BOLD}$((LIST_INDEX_NOW+1))/${LIST_INDEX_MAX} $((25*(${LIST_INDEX_NOW}*4+0)/LIST_INDEX_MAX))%${FONT_RESET}${FONT_YELLOW} Begin working with list \"${UPKG_LIST_NOW}\"${FONT_RESET}"
	sudo ${APT} install --only-upgrade $(< ${UPKG_LIST_NOW} ) -y
	
	echo -e "${FONT_CYAN}${FONT_BOLD}$((LIST_INDEX_NOW+1))/${LIST_INDEX_MAX} $((25*(${LIST_INDEX_NOW}*4+1)/LIST_INDEX_MAX))%${FONT_RESET}${FONT_YELLOW} Syncing${FONT_RESET}"
	sync

	echo -e "${FONT_CYAN}${FONT_BOLD}$((LIST_INDEX_NOW+1))/${LIST_INDEX_MAX} $((25*(${LIST_INDEX_NOW}*4+2)/LIST_INDEX_MAX))%${FONT_RESET}${FONT_YELLOW} Check dependency & cleanup ${FONT_RESET}"
	sudo apt-get install -f -y
	sudo apt-get autoremove -y

	echo -e "${FONT_CYAN}${FONT_BOLD}$((LIST_INDEX_NOW+1))/${LIST_INDEX_MAX} $((25*(${LIST_INDEX_NOW}*4+3)/LIST_INDEX_MAX))%${FONT_RESET}${FONT_YELLOW} List \"${UPKG_LIST_NOW}\" finished. Taking a break for ${DELAY_TIME} second(s)...${FONT_RESET}"
	LIST_INDEX_NOW=$((LIST_INDEX_NOW+1))
	sync
	sleep ${DELAY_TIME}

	mv ${UPKG_LIST_NOW} ${UPKG_LISTS_DONE}
done


# Clean-up
echo -e "${FONT_YELLOW}\n\nALL DONE! CLEANING UP... ${FONT_RESET}"
rm -f ${UPKG_LIST_ALL} && echo -e "Removed list file : ${UPKG_LIST_ALL}"
rm -rf ${UPKG_LISTS_READY} && echo -e "Removed remaining packages lists : ${UPKG_LISTS_READY}"
rm -rf ${UPKG_LISTS_DONE} && echo -e "Removed processed packages lists : ${UPKG_LISTS_DONE}"
echo -e "\n"
sync
sleep 1


exit 0
