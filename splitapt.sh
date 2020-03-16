#!/bin/bash

# Constants
FONT_RESET='\e[0m'
FONT_BLACK='\e[30m'
FONT_YELLOW='\e[93m'
FONT_MAGENTA='\e[95m'
FONT_CYAN='\e[96m'
FONT_BACK_YELLOW='\e[103m'
FONT_BOLD='\e[1m'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
UPKG_LIST_ALL="${DIR}/.upkg_list.txt"
UPKG_LISTS_READY="${DIR}/.upkg_lists_ready"
UPKG_LISTS_DONE="${DIR}/.upkg_lists_done"
INSTALL_SCRIPT="${DIR}/splitapt-inst.sh"


# Title
#clear
echo -e "\n${FONT_BOLD}${FONT_BACK_YELLOW}${FONT_BLACK}           APT SPLIT UPGRADER   v0.5          ${FONT_RESET}"
echo -e "${FONT_BACK_YELLOW}${FONT_BLACK}    upgrade package list preparation module   ${FONT_RESET}\n\n"


# Prepare INSTALL MODULE (splitapt-inst.sh)
echo -e "\n${FONT_CYAN}${FONT_BOLD}[1/8]${FONT_RESET}${FONT_YELLOW} Checking required module files...${FONT_RESET}"
if [! -f ${INSTALL_SCRIPT} ]; then
	echo -e "\n${FONT_BOLD}${FONT_MAGENTA} Install module (${INSTALL_SCRIPT}) not found, aborting.${FONT_RESET}\n"
	echo -e "${FONT_MAGENTA} Clone this script repository and try again.${FONT_RESET}\n"
	echo -e "${FONT_MAGENTA}  git clone https://github.com/hdavid0510/splitapt && chmod +x splitapt/splitapt.sh ${FONT_RESET}\n"
	exit 1
fi
sudo chmod +x ${INSTALL_SCRIPT}
sync
sleep 1


# Prepare directories
echo -e "\n${FONT_CYAN}${FONT_BOLD}[2/8]${FONT_RESET}${FONT_YELLOW} Preparing directories...${FONT_RESET}"
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
echo -e "\n${FONT_CYAN}${FONT_BOLD}[3/8]${FONT_RESET}${FONT_YELLOW} Preparing required APT softwares${FONT_RESET}"
# Need to check if apt is locked, not working
sudo dpkg --configure -a
sudo apt install aptitude -y --show-progress
sync
sleep 1


# Get list
echo -e "\n${FONT_CYAN}${FONT_BOLD}[4/8]${FONT_RESET}${FONT_YELLOW} Get upgrade list via aptitude${FONT_RESET}"
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
echo -e "\n${FONT_CYAN}${FONT_BOLD}[5/8]${FONT_RESET}${FONT_YELLOW} Split list files.${FONT_RESET}"
while true; do
	echo -e -n "${FONT_MAGENTA} Number of packages per file : ${FONT_RESET}"
	read SPLIT_LINE
	if [[ ${SPLIT_LINE} =~ '^[0-9]+$' ]] ; then
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
echo -e "\n${FONT_CYAN}${FONT_BOLD}[6/8]${FONT_RESET}${FONT_YELLOW} Check depencency ${FONT_RESET}"
sudo apt install -f -y
sudo apt autoremove -y
sync
sleep 1


# Cache clean
echo -e "\n${FONT_CYAN}${FONT_BOLD}[7/8]${FONT_RESET}${FONT_YELLOW} Clean apt cache ${FONT_RESET}"
sudo rm -rf /var/cache/apt/archives/apt-fast
sudo apt clean
sync
sleep 1


# APT-FAST check
echo -e "\n${FONT_CYAN}${FONT_BOLD}[8/8]${FONT_RESET}${FONT_YELLOW} Check essential utilities installed ${FONT_RESET}"
sudo apt install apt-fast nano -y --show-progress
sync
sleep 1


# Start install module!
echo -e "\n${FONT_CYAN}${FONT_BOLD} Preparation done! ${FONT_RESET}"
sync
sleep 1
./${INSTALL_SCRIPT}