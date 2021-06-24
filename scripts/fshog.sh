#!/bin/bash

set -o errexit
set -o noglob
set -o nounset
set -o pipefail
set +o noclobber
IFS=$'\n\t'

usage () {
	printf "usage:\n"
	printf "fshog [1-99]\n"
	printf "       where 1-99 is the percent of filesystem to consume\n"
	exit 0
}

fshog () {
	percent=$1
	available=$(df -k /tmp --output=avail | tail -1)
	hog=$(echo $available*0.$percent | bc | cut -f1 -d.)
	echo "fshog: claiming $percent% of available filesystem space"
	echo "       available space = $available kB"
	hogfile=$(mktemp)
	echo "       hogging $hog kB in $hogfile"
	fallocate -l ${hog}KiB $hogfile
	while true
	do
	read -n 1 -r -e -d $'\n' -p "       press r to REPEAT, g to add a percent, or c to remove hog file " _response
		case "${_response:-c}" in
			r|R)
				_available=$(df -k /tmp --output=avail | tail -1)
				echo "       available space = $_available kB"
				_hog=$(echo $_available*0.$percent | bc | cut -f1 -d.)
				echo "       hogging $_hog kB in $hogfile"
				fallocate -l ${_hog}KiB $hogfile
				;;
			g)
				if [[ $percent = 99 ]]
				then
					echo "       that's enough!"
					echo "       removing $hogfile"
					rm $hogfile
					exit
				fi
				percent=$((percent + 1))
				available=$(df -k /tmp --output=avail | tail -1)
				echo "       available space = $available kB"
				echo "       hogging $percent%"
				_hog=$hog
				hog=$(echo $available*0.$percent | bc | cut -f1 -d.)
				hog=$((hog + _hog))
				echo "       hogging $hog kB in $hogfile"
				fallocate -l ${hog}KiB $hogfile
				;;
			*)
				echo "       removing $hogfile"
				rm $hogfile
				exit
				;;
		esac
	done
}

if [[ -z "${1:-}" ]]
then
	usage
else
	if [[ ! $1 =~ ^[0-9]+$ ]]
	then
		echo "error: integer range of 1-99 only"
		usage
	fi
	if [[ $1 -gt 0 ]] && [[ $1 -lt 100 ]]
	then
		fshog $1
	else
		echo "error: integer range of 1-99 only"
		usage
	fi
fi
