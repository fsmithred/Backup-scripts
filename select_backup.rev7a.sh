#!/usr/bin/env bash
# select_backup.rev7a.sh

# rev7a:
# Removed the use of an array.
# Changed the rsync line to back up user's entire home,
# except for what gets excluded. 
# Added function: ask_exclusions, which creates
# a file with a list of items to exclude.
# Temporarily, added a line to exclude all
# hidden files and directories.
# Removed the call to clean_up in the ask_for function, since
# it's just a leftover from another script.
# Need to add some kind of clean up (unmount and delete
# the exclusions file) if the script is aborted with a "no" answer.

# rev5:
# Added functions: check_root, show_help
# Replaced getopts with manual loop for handling options.
# Moved the help part up to the top. Otherwise, the script
# just goes right to asking for the user.
# Added test for directory vs. file before running rsync.



# the help text will be shown in case the user uses the -h option
# Other options can easily be added later.

help_text="
Usage:
$0  <username>

This script will backup FOLDERS and FILES in your home.
You can store the backup on an external/internal hd, an usb-stick...
You will be asked which files and folders you want to add.
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
#      --) shift; break;;
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
#BU_FOLDERS=()
EXCLUSIONS="/root/scripts/select_excludes"

# if you want to set them static, uncomment the following:
echo -n "
    Tell us the user: "
read BU_USER
echo -n "
    Tell us the backup device: "
read BU_DEV
echo -n "
    Tell us the backup mount-point: "
read BU_MOUNTPOINT

#  Options (only help at this time)
#########################################################################




# Functions:
############################################################################


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
echo -n "
    You want to go on? (answer yes or no): "
read answer
if [[ $answer = yes ]] || [[ $answer = y ]]  || [[ $answer = Yes ]] || [[ $answer = Y ]] 
then
    echo "
    Ok, we will move on."
    echo
else
    echo "
    Your answer has not been yes.
    Script will die now."
    echo 
#    clean_up
    exit 1
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


#  check if it is a valid device:
if ! [[ -b $BU_DEV ]]
then
    echo "
    You did not add a valid device. Start over"
    exit 0
fi 


########################################################################
# creating the LIST of files and folders to be excluded
# asking for folders:
######################
echo "
    You are asked about:
    FOLDERS in your home"
echo 

function ask_exclusions {
cd /home/"$BU_USER"
for e in * 
do

        echo -n "
        Do you want to skip $e (yes or no): "
        read answer
        case "${answer:0:1}" in 
            [Yy]) echo $e >> "$EXCLUSIONS" ; echo "$e will be skipped" ;;
               *) echo "$e will be backed up" ;;
        esac 
cd -
done
}

# exclude all hiddens items automatically, for testing
echo ".[a-z,A-Z,0-9]*" >> "$EXCLUSIONS"


# mounting the backup device
#############################################################################

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

# mount it
echo "
    WE will mount $BU_DEV at $BU_MOUNTPOINT
    "


mount $BU_DEV $BU_MOUNTPOINT
check_exit

echo "
    We mounted $BU_DEV at $BU_MOUNTPOINT
    Here is the actual content of $BU_MOUNTPOINT:"
ls "$BU_MOUNTPOINT"

ask_for
ask_exclusions

# rsyncing it
echo -n "
    We rsync your data with $BU_MOUNTPOINT now.
    Be patient.
    The following items will be skipped.
    "
cat "$EXCLUSIONS"

# TODO
# Need to unmount the backup drive and delete
# the excludes file if answer is No.
ask_for


# rsync the user's home, excluding items that were put in the exclusions file.

rsync -auvx --delete --exclude-from="$EXCLUSIONS" /home/"$BU_USER"/  "$BU_MOUNTPOINT"
check_exit

# finish
echo " 
    rsync did finish with succes
    We umount $BU_MOUNTPOINT now
    "

rm "$EXCLUSIONS"
umount $BU_MOUNTPOINT
check_exit

echo "
    Seems like all went fine.
    Bye"

exit 0
