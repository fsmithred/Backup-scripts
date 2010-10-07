#!/usr/bin/env bash
# select_backup.rev9.sh


# the help text will be shown in case the user uses the -h option
# Other options can easily be added later.

help_text="
Usage:
$0  <username>

This script will backup FOLDERS and FILES in your home.
You can store the backup on an external/internal hd, an usb-stick...
Use create_exclusions.sh to generate a file of rsync exclusions.
If unsure run \"fdisk -l\" and \"ls /home/username\" first 
"


function show_help {
	echo "$help_text"
    exit 0
}

# Manual loop to handle any arbitrary set of options.
while [[ $1 == -* ]]; do
    case "$1" in
      -h|--help|-\?) show_help; exit 0;;
      -*) echo "
    invalid option: $1
    
    valid options: -h, --help, -?,        show this help message
              " 
              1>&2; show_help; exit 1;;
    esac
done


clear; date
echo 

# Variables:
#######################################################################
BU_USER=
BU_DEV=
BU_MOUNTPOINT=
EXCLUSIONS=

# if you want to set them static, comment out the following:
echo -n "
    Tell us the user: "
read BU_USER
echo -n "
    Tell us the backup device: "
read BU_DEV
echo -n "
    Tell us the backup mount-point: "
read BU_MOUNTPOINT
echo -n "
    Give the full path (with filename)
    to the rsync exclusions file: "
read EXCLUSIONS


function check_root {
if [[ $(id -u) -ne 0 ]]
then
    echo "
    rerun as root"
    echo 
    exit 0
fi
}

function ask_for {
	echo "
	Continue? (yes or no)
	"
	read answer
	case ${answer} in
	    [Yy]*)  echo "
	                 OK
	                " ; break ;;
	        *) echo "
	                Your answer has not been yes.
	                Script will die now
	                "  ; umount "$BU_MOUNTPOINT" ; exit 0 ;;
	esac
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


#  check if it is a valid device:
if ! [[ -b $BU_DEV ]]
then
    echo "
    You did not add a valid device. Start over"
    exit 0
fi 


# create BU_MOUNTPOINT if necessary

if ! [[ -d $BU_MOUNTPOINT ]] 
then
    mkdir "$BU_MOUNTPOINT" 
fi 
 
 
# make sure the backup device isn't
# already mounted, then mount it.

if $(df | grep -q $BU_DEV)
then
  umount $BU_DEV
fi
echo "
    WE will mount $BU_DEV at $BU_MOUNTPOINT
    "
mount $BU_DEV $BU_MOUNTPOINT
check_exit

echo "
    We mounted $BU_DEV at $BU_MOUNTPOINT
    Here is the actual content of $BU_MOUNTPOINT:
    "
ls -a "$BU_MOUNTPOINT"
ask_for


# rsyncing it
echo -n "
    We rsync your data with $BU_MOUNTPOINT now.
    Be patient.
    The following items will be skipped.
    "
sleep 3
cat "$EXCLUSIONS"
ask_for


# rsync the user's home, excluding items that were put in the exclusions file.

rsync -auvx --delete --exclude-from="$EXCLUSIONS" /home/"$BU_USER"/  "$BU_MOUNTPOINT"
check_exit

# finish
echo " 
    rsync did finish with succes
    Unmounting $BU_MOUNTPOINT now
    "

umount "$BU_MOUNTPOINT"
check_exit

echo "
    Seems like all went fine.
    Bye"

exit 0
