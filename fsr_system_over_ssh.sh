#!/usr/bin/env bash
# back up system over ssh

# IP address or hostname of the destination system
REMOTE_HOST="some-host"

# Source path (should be / on localhost for system backup.)
SRC="/"

# Destination path (should be / on remote host for system backup.)
DEST="/"

# Full (absolute) path to the ssh key file
KEYFILE="/root/.ssh/id_rsa"

# Full (absolute) path to the rsync excludes file
EXCLUDES="/path/to/rsync_system_excludes"

# Backup user (should be root to back up the system)
BU_USER="root"


function check_root {
if [[ $(id -u) -ne 0 ]]
then
    echo "
    rerun as root"
    echo 
    exit 0
fi
}

function check_exit {
if  [[ $? -ne 0 ]]
then
    echo "
    An error occured"
    echo
    exit 0
fi 
}  

function ask {
	echo "
	$SRC on the local machine will be backed up
	incrementally to $DEST on $REMOTE_HOST.

	Hit \"Enter\" to continue,
	\"S\" or \"s\" to Show the excludes file and exit,
	\"n\", \"e\", or \"x\" to Exit the script.
	 "
	read answer
	case "$answer" in          
	            [Ss]) echo "
	  Contents of $EXCLUDES:
	            " 
	            cat "$EXCLUDES" ; echo ; exit 0 ;; 
	  [Nn]|[Ee]|[Xx]) echo "
	  Exiting...
	                " 1>&2 ; exit 1 ;;
	               *) echo "
	                 OK
	                "  ;;
	esac
}


clear ; date
echo

check_root
ask


rsync  -avx --exclude-from="$EXCLUDES"  --delete-after -e "ssh -c blowfish -i $KEYFILE " "$SRC" "$BU_USER"@"$REMOTE_HOST":/"$DEST"
check_exit

echo "
    Done!
    "
exit 0
