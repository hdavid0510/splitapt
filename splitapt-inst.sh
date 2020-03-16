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
SETUP_SCRIPT="${DIR}/splitapt.sh"


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
	if [[ ${DELAY_TIME} =~ '^[0-9]+$' ]] ; then
		if (( ${DELAY_TIME} < 0 || ${DELAY_TIME} > 60 )) ; then
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
	sudo apt-fast install --only-upgrade $(< ${UPKG_LIST_NOW} ) -y
	
	echo -e "${FONT_CYAN}${FONT_BOLD}$((LIST_INDEX_NOW+1))/${LIST_INDEX_MAX} $((25*(${LIST_INDEX_NOW}*4+1)/LIST_INDEX_MAX))%${FONT_RESET}${FONT_YELLOW} Syncing${FONT_RESET}"
	sync
C
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