#!/usr/bin/env bash
# select_backup.rev5.sh

# Added functions: check_root, show_help
# Replaced getopts with manual loop for handling options.
# Moved the help part up to the top. Otherwise, the script
# just goes right to asking for the user.
# Added test for directory vs. file before running rsync.

# TEST RESULTS
# Won't delete. Tried --delete-after and --delete

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
BU_FOLDERS=()

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
    clean_up
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
# creating the LIST of files and folders to be backed up
# asking for folders:
######################
echo "
    You are asked about:
    FOLDERS in your home"
echo 

index=0
function ask_folders {
for e in /home/$BU_USER/* 
do
    if [[ -d $e ]]
    then 
        echo -n "
        Do you want to make a backup of $e (yes or no): "
        read answer
        case "${answer:0:1}" in 
            [Yy]) BU_FOLDERS[$index]="$e"  ; ((index+=1)) ; echo "$index" ;;
               *) echo "$e will be skipped during backup" ;;
        esac 
    fi 
done
}

echo -n  "
    You want to backup the FOLDERS of your home-directory? ( yes or no):  "
read answer
case  "${answer:0:1}" in 
   [Yy]) ask_folders ;;
   * ) echo "ok, no files will be backed up" ;;
esac

#asking for FILES
##################
echo "
    You are asked about:
    FILES in your home"
echo
function ask_files {
for e in /home/$BU_USER/* 
do
    if [[ -f $e ]]
    then 
        echo -n "
        Do you want to make a backup of $e (yes or no): "
        read answer
        case "${answer:0:1}" in 
            [Yy]) BU_FOLDERS[$index]="$e" ; ((index+=1)) ; echo "$index" ;;
               *) echo "$e will be skipped during backup" ;;
        esac 
    fi 
done
}


echo -n  "
    You want to backup the FILES too ( yes or no):  "
read answer
case  "${answer:0:1}" in 
   [Yy]) ask_files ;;
   * ) echo "ok, no files will be backed up" ;;
esac

# replace $e with rsync, this is the test run:
for e in "${BU_FOLDERS[@]}"
do
  echo "$e will be backed up"
done 

ask_for 


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


############################################################
# rsyncing it
echo -n "
    We rsync your data with $BU_MOUNTPOINT now.
    Be patient"
sleep 3

# rsync the BU_FOLDERS
for i in "${BU_FOLDERS[@]}"
do
    if [[ -d $i ]]
    then
      echo "rsyncing $i"
      rsync -auv --delete "$i"/*  "$BU_MOUNTPOINT"/${i##*/}
      else
      echo "rsyncing $i"
      rsync -auv --delete "$i" "$BU_MOUNTPOINT"/${i##*/}
      fi
done


###############################################################
# finish
echo " 
    rsync did finish with succes
    We umount $BU_MOUNTPOINT now
    "

umount $BU_MOUNTPOINT
check_exit

echo "
    Seems like all went fine.
    Bye"

exit 0

