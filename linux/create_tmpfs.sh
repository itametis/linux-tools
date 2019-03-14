#!/usr/bin/env bash
# This file is part of LINUX-TOOLS.
#
# LINUX-TOOLS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# LINUX-TOOLS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LINUX-TOOLS.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
#
# If you need to develop a closed-source software, please contact us
# at 'social@itametis.com' to get a commercial version of LINUX-TOOLS,
# with a proprietary license instead.
#

## USAGE EXAMPLE :  create_tmpfs 1000 "/path/to/an/empty/folder"
## This will create a virtual disk of 1000 MB mounted on folder "/path/to/an/empty/folder".


# Contains the result of a function :
FN_RESULT=""

# The size of the new tmpfs partition :
PART_SIZE="$1"

# The path of the new tmpfs partition :
PART_PATH="$2"


# Returns "true" if this script is run by root.
# @return : "true" if this script is run as root or using sudo.
is_user_root() {
	FN_RESULT="false"

	if [ `whoami` == "root" ]; then
		FN_RESULT="true"
	fi

	echo "$FN_RESULT"
}

# Returns "true" if this script has exactly $1 argument.
# @param $1 : This script args number.
# @param $2 : The number of args this script should have.
# @return : "true" if this script have the right number of args.
# @example : is_arg_number_ok "$#" "2"
is_arg_number_ok() {
	FN_RESULT="false"

	if [ "$#" -eq "$1" ]; then
		FN_RESULT="true"
	fi

	echo "$FN_RESULT"
}

# Exits this script if the first argument match the second.
# @param $1 : The parameter to check.
# @param $2 : The value with which the parameter $1 has to match.
# @param $3 : The error code to display.
# @param $4 : [OPTIONAL] The reason of the error (i.e. explanation). If this equals "0" then the "display_command_usage" is used.
# @example : exit_if "$FN_RESULT" "true" "23"
# 	     exit_if "$FN_RESULT" "true" "23" "Wrong path"
exit_if() {
	let "exit_code = 0"

	if [ "$3" != "" ] && [[ "$(is_integer $3)" == "true" ]]; then
		let "exit_code = $3"
	fi

	if [ "$1" == "$2" ]; then
		if [ "$4" != "" ]; then
			if [ "$4" == 0 ]; then
				display_command_usage
			else
				echo "$4"
			fi
		fi

		exit $exit_code
	fi
}

# Creates mount point directory if necessary.
# @param $1 : The path of the directory.
# @example : create_mount_dir "$PART_PATH"
create_mount_dir() {
	if [ ! -d "$1" ]; then
		mkdir -p "$1"
	fi
}

# Returns "true" if $1 represents an empty folder.
# @param $1 : The path to check.
# @return : "true" if the path in parameter is an empty folder.
is_empty_folder() {
	FN_RESULT="false"

	if [ "$(ls -A $1)" == "" ]; then
		FN_RESULT="true"
	fi

	echo "$FN_RESULT"
}

# Displays instructions on how to use this script.
display_command_usage() {
	echo "Command usage : 'create_tmpfs <SIZE> <PATH>'"
	echo "    - SIZE : The disk's size (in Mo) to create in memory"
	echo "    - PATH : The folder where to create the virtual disk"
}

# Returns "true" if the parameter is empty.
# @param $1 : The String to check.
# @return : "true" if "$1" is an empty String.
is_empty_arg() {
	FN_RESULT="true"

	if [ "$1" != "" ]; then
		display_command_usage
		FN_RESULT="false"
	fi

	echo "$FN_RESULT"
}

# Returns "true" if "$1" contains an integer.
# @param $1 : The String to check.
# @return : "true" if "$1" contains only digits.
is_integer() {
	FN_RESULT="false"
	regex_number='^[0-9]+$'

	if [[ "$1" =~ $regex_number ]]; then
		FN_RESULT="true"
	fi

	echo "$FN_RESULT"
}


##################
# Validity check #
##################

# Checks this script is run as root or sudo :
exit_if `is_user_root` "false" 1 "Error : You have to run this script as root or with sudo !"

# Checks this script has the right number of argument :
exit_if `is_arg_number_ok "$#" "2"` "false" 2 "0"

# Checks argument are not empty :
exit_if `is_empty_arg "$PART_SIZE"` "true" 3 "Error : The first argument is empty !"
exit_if `is_empty_arg "$PART_PATH"` "true" 4 "Error : The second argument is empty !"

# Checks first argument is an integer :
exit_if `is_integer "$PART_SIZE"` "false" 5 "Error : The first argument must be an integer !"

# Checks mount directory exists :
create_mount_dir "$PART_PATH"

# Checks the mount folder is empty :
exit_if `is_empty_folder "$PART_PATH"` "false" 6 "Error : The specified path is not empty !"


#################
# Disk creation #
#################

mount -t tmpfs -o size=${PART_SIZE}m tmpfs "$PART_PATH"

