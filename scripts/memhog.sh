#!/bin/bash
# wrapper script for stress-ng to test memory on linux
# jason.lindemuth@nutanix.com
#
# prerequisites for centos
# install stress-ng:
# $ sudo yum install epel-release
# $ sudo yum install snapd
# $ sudo systemctl enable --now snapd.socket
# $ sudo ln -s /var/lib/snapd/snap /snap
# $ sudo snap install stress-ng
# install bc: 
# $ yum install bc 

# use safe bash scripting practices
set -o errexit
set -o noglob
set -o nounset
set -o pipefail
set +o noclobber
IFS=$'\n\t'

memhog () {
	percent=$1
	available=$(awk '/MemAvailable/{printf "%d\n", $2;}' < /proc/meminfo)
	hog=$(echo $available*0.$percent | bc | cut -f1 -d.)
	echo "memhog: using $percent% of available memory"
	echo "        available memory = $available kB"
	echo "        hogging $hog kB"
	echo "        --> press control-c to kill memhog"
	stress-ng --vm-bytes ${hog}k --vm-keep -m 1 -q
}

usage () {
	printf "usage:\n"
	printf "memhog [1-99]\n"
	printf "       where 1-99 is the percent of available memory to consume\n"
	exit 0
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
		memhog $1
	else
		echo "error: integer range of 1-99 only"
		usage
	fi
fi
