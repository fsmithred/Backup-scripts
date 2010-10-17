#!/usr/bin/env bash
# back up system over ssh

# NOTES -- IMPORTANT!!!
# Edit the variables to suit your needs. 
# Make sure the destination path is correct!!!
# To back up something other than the full system, change 
# SRC and DEST. To run it as an unprivileged user,
# comment out "check_root" on or about line 86, and change BU_USER. 
# If any directories are mount points for another 
# partition (like /home, for instance) remove the "x"
# from "rsync -auvx" if you want to include it in the backup.


# IP address or hostname of the destination system
REMOTE_HOST="some-host"

# Source path (should be "/" on localhost for system backup.)
SRC="/"

# Destination path (WARNING!!! UNTESTED!!!)
# Set to "/" on remote host if you want the backup system 
# to be a working clone. If so, you will need to exclude 
# any files that have configurations specific to that host.
# Otherwise, change it to some backup directory on the remote host.
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


rsync  -auvx --exclude-from="$EXCLUDES"  --delete-after -e "ssh -c blowfish -i $KEYFILE " "$SRC" "$BU_USER"@"$REMOTE_HOST":/"$DEST"
check_exit

echo "
    Done!
    "
exit 0
