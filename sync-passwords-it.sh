#!/bin/bash
# Important note:
# If you don't synchronize but then edit the other file,
# the newer modification time on the second file edited
# will cause data to be overridden.
# The solution would be to merge manually
# (Database --> Merge from database).

#####################
##  Configuration  ##
#####################

# Name of your remote storage as defined in Rclone
DRIVE_NAME="remote"

# Name and locations of the passwords file
DB_FILE_NAME="Database.kdbx" # Name of the keepass database
LOCAL_LOCATION="/run/media/$USER/MyData/Casa/Keepass/" # The place where the keepass database is stored 
LOCAL_BKUP=$LOCAL_LOCATION"bkup/" # The place where the keepass backup files are to be saved 
REMOTE_LOCATION="kp" # The remote place where the keepass database is stored 
REMOTE_BKUP=$REMOTE_LOCATION"/bkup" # The remote place where the keepass backup files are to be saved 
#if type -a zenity 2>&1 >/dev/null; then ZEN=1; fi
#####################
function format_datetime_from_string ()
{
	echo `date -d "$1" +"%F %T.%3N"`
}

# Parse local passwords file modification time using the stat command
function get_local_passwords_mtime ()
{
	local string=`stat -c %y $LOCAL_PATH | cut -d ' ' -f 1,2;`
	echo `format_datetime_from_string "$string"`
}


function showMsg ()
{
	whiptail --msgbox "$1" 11 75
}

function showPopup ()
{
	notify-send -t 100 "SYNC Keepass files" "$1"
}

function showInfo ()
{
	TERM=ansi whiptail --title "SYNC Keepass files" --infobox "$1" 11 75
	sleep "$2"
}

function showYN()
{
	# Input "Question" "Height" "Width" "1 if default no" "timeout value"
	answer=$(whiptail --clear --title "SYNC Keepass files" \
	`if [[ $4 = 1 ]]; then echo --defaultno; fi` \
	`if [[ $5 =~ ^[0-9]\+$ ]]; then echo --timeout $5; fi` \
	--backtitle "What shall we do?" \
	--yesno "$1" "$2" "$3" 3>&1 1>&2 2>&3) 
	return $answer
}

function showError ()
{
	printf "${bred} ERROR : ${end}${byel}$@ \n ${byel} Check if to continue ${end}"
	whiptail --title "ERROR" --msgbox "ERROR! : $1" 11 75
	exit
}

# Parse remote passwords file modification time using Rclone's lsl command
# See: https://rclone.org/commands/rclone_lsl/
function get_remote_passwords_mtime ()
{
	output=`rclone lsl $DRIVE_NAME:$REMOTE_PATH 2>/dev/null`
	if [ $? -eq 3 ]; then
		unset output
		return 1
	else
		local string=`echo "$output" | tr -s ' ' | cut -d ' ' -f 3,4;`
		echo `format_datetime_from_string "$string"`
		unset output
		return 0
	fi
}

function passwords_remote_bkup ()
{
	showInfo "\nRemote copy of the old password file to the backup folder...\n" 3
	REMOTE_BKUP_PATH="$REMOTE_BKUP/$DB_FILE_NAME"
	rclone copy $DRIVE_NAME:$REMOTE_PATH $DRIVE_NAME:$REMOTE_BKUP
	remote_date=`get_remote_passwords_mtime 2>/dev/null | awk -F' ' '{print $1"_"$2}' | cut -d '.' -f 1;`
	DB_BK_FILE_NAME=${remote_date}_$DB_FILE_NAME
	sleep 5
	showInfo "\nRename the old password file in the backup folder...\nwith the name: ${DB_BK_FILE_NAME}" 3
	rclone moveto $DRIVE_NAME:$REMOTE_BKUP_PATH $DRIVE_NAME:$REMOTE_BKUP/$DB_BK_FILE_NAME
}

function passwords_local_bkup ()
{
	DB_BK_FILE_NAME=`date -r $LOCAL_LOCATION$DB_FILE_NAME '+%Y-%m-%d_%H:%M:%S_'`"$DB_FILE_NAME"
	showInfo "\nLocal copy of the old password file in the backup folder...\nwith the name: ${DB_BK_FILE_NAME}" 3
	LOCAL_BKUP_PATH="$LOCAL_BKUP$DB_BK_FILE_NAME"
	cp $LOCAL_PATH $LOCAL_BKUP_PATH
}

function passwords_export ()
{
	showInfo "\nCopying the local password file to the remote driver...\n" 3
	rclone copy $LOCAL_PATH $DRIVE_NAME:$REMOTE_LOCATION
}

function passwords_import ()
{
	showInfo "\nCopying the remote password file to the local driver...\n" 3
	rclone copy $DRIVE_NAME:$REMOTE_PATH $LOCAL_LOCATION
}
################
# Compose full path to local and remote database files
LOCAL_PATH="$LOCAL_LOCATION$DB_FILE_NAME"
REMOTE_PATH="$REMOTE_LOCATION/$DB_FILE_NAME"

# Alias import and export commands and make them available within the functions
#alias passwords_remote_bkup="rclone copy $DRIVE_NAME:$REMOTE_PATH $DRIVE_NAME:$REMOTE_BKUP_PATH"
#alias passwords_local_bkup="cp $LOCAL_PATH $LOCAL_BKUP_PATH"
#alias passwords_export="showMsg 'Copying the remote password file to the local driver...\n' | rclone copy $LOCAL_PATH $DRIVE_NAME:$REMOTE_LOCATION"
#alias passwords_import="showMsg 'Copying the local password file to the remote driver...\n' | rclone copy $DRIVE_NAME:$REMOTE_PATH $LOCAL_LOCATION"
#shopt -s expand_aliases

function sync_passwords ()
{
	if [ ! -f ${LOCAL_PATH} ]; then
		showInfo "The local file is not present.\n\nI can't do anything!" 5
		return 1
	fi
	showInfo "\nChecking the last modified dates of local and remote files\n\n                  Please wait..." 3

	# Storing the values so they can be used for printing and then conversion
	local human_readable_local_mtime=`get_local_passwords_mtime`
	human_readable_remote_mtime=`get_remote_passwords_mtime 2>/dev/null`

	# In case there is no remote yet
	if [ $? -ne 0 ]; then
		MSG="No remote password file!\n\nExport...\n"
		showYN "${MSG}\n            Do you want to copy local file to remote?"
		if [ $? == "0" ]; then
			showInfo "\n\n\nExport..." 3
			passwords_export
		else
			showInfo "\n\n\n                               Aborted!" 5
			return 0
		fi
		showInfo "\n\n\n                               Done!" 5
		return 0
	fi

	# Printing modification times to the user
		MSG="The local password file has been modified on: $human_readable_local_mtime\nThe remote password file has been modified on: $human_readable_remote_mtime\n\n"

	# The conversion is required for the comparison in the following if statement
		local_mtime_in_seconds_since_epoch=$(date -d "$human_readable_local_mtime" +%s)
		remote_mtime_in_seconds_since_epoch=$(date -d "$human_readable_remote_mtime" +%s)
		unset human_readable_remote_mtime

        # Handle local being newer than remote
		if [ "$local_mtime_in_seconds_since_epoch" -gt "$remote_mtime_in_seconds_since_epoch" ]; then
			MSG="${MSG}      The remote password file is older than the local one!\n"
			showYN "${MSG}\n                            Do you want to update it?"
			if [ $? == "0" ]; then
				showInfo "\n\n\n                               Exporting..." 1
				passwords_remote_bkup
				passwords_export
			else
				showInfo "\n\n\n                               Aborted!" 5
				return 0
			fi
			showInfo "\n\n\n                               Done!" 5
			return 0
        # Handle remote being newer than local
		elif [ "$local_mtime_in_seconds_since_epoch" -lt "$remote_mtime_in_seconds_since_epoch" ]; then
			MSG="${MSG}      The local password file is older than the remote one!\n"
			showYN "${MSG}\n                            Do you want to update it?"
			if [ $? == "0" ]; then
				showInfo "\n\n\n                               Importing..." 1
				passwords_local_bkup
				passwords_import
			else
				showInfo "\n\n\n                               Aborted!" 5
				return 0
			fi
			showInfo "\n\n\n                               Done!" 5
			return 0
		# Handle remote sama as local
		else
			showInfo "${MSG}\n              Password files are already synchronized!" 8
			return 0
        fi
}

if ping -q -w 1 -c 1 8.8.8.8 > /dev/null; then
	sync_passwords
else
	showError "\n\n       There is no internet connection."
fi
