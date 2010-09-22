#!/bin/bash
# system backup script 
# with date-stamped, encrypted archive


clear; date
echo 

# Two or three of these scripts went around behind the barn when
# nobody was looking, and this is their offspring.


BU_MP="/media/backup"
BU_DEV= 
BU_SYS_EXCLUDE="/path/to/rsync_system_excludes"
ARCHIVE="/path/to/tar-files"
TAR_FILE="$ARCHIVE/backup_$(hostname)__OS_$(date +%m-%d).tar.gz"


# Functions: check_root; check_exit
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


# the help text will be shown in case the user uses the -h option
help_text="
Usage:
$0  /dev/sdxY  

(Where /dev/sdxY is replaced with the partition on
the external drive where the backup copy will reside.)

See rsync_system_excludes for the list of exclusions.
" 

while getopts h option
do
case $option in
                h) echo "$help_text" ;
                   exit 0
        esac
done


check_root

# create BU_MP if necessary

if ! [[ -d $BU_MP ]] 
then
    mkdir "$BU_MP" 
fi 


# check the command argument

if [ "$#" -eq  1 ]
  then
    BU_DEV="$1"
    echo "
    We will mount "$1" on "$BU_MP", correct? 
    "
    read answer
    case "$answer" in 
        "yes" | "y" | "Yes" ) echo "ok" ;;
        "no" | "n" | "No" ) echo " Check the code" 
                            exit 0 ;;
         * ) echo "you are too dumb to give a simple answer" 
             exit 0 ;;
    esac
  else
    echo "You missed the device to be mounted. Do it now"
    fdisk -l
    echo -n "which one, full name, like /dev/sdx? "
    read BU_DEV
    echo "
    We will mount "$BU_DEV" on "$BU_MP", correct? 
    "
    read answer
    case "$answer" in
             "yes" | "y" | "Yes") echo "ok" ;;
             "no" | "n" | "No" ) echo "Check the  code" 
                                 exit 0 ;;
              * ) echo "Visit a shrink" 
                  exit 0
    esac
 fi
 
 
# make sure the backup device isn't
# already mounted, then mount it.

if $(df | grep -q $BU_DEV)
then
    umount "$BU_DEV"
fi
mount "$BU_DEV" "$BU_MP"
echo "
    Contents of "$BU_MP" 
    "
ls "$BU_MP"

echo -n "
    Would you like to run rsync now? 
    "
read answer
case "$answer" in 
    "yes" | "y" | "Yes" ) echo "ok" ;;
    "No" | "n" | "No" ) echo "Check the code" 
                        umount "$BU_MP"
                        exit 0 ;;
     * ) echo "Have a break, pal" 
               umount "$BU_MP"
               exit 0
esac 


# run the backup

rsync -auvx --exclude-from="$BU_SYS_EXCLUDE"  --delete-after / "$BU_MP"
check_exit
echo "
    Rsync did finish, here is the actual content of "$BU_MP" 
    If it is wrong you are on your own.
    "
ls "$BU_MP"


# Ask if a tarred, encrypted, date-stamped archive is desired.

echo -n "
    Would you like a date-stamped and encrypted archive
    to be created at $TAR_FILE.gpg?
    "
read answer
if [[ $answer = yes ]] || [[ $answer = y ]]  || [[ $answer = Yes ]] || [[ $answer = Y ]] 
then
    tar -czf  $TAR_FILE  $BU_MP
    gpg -c $TAR_FILE
    rm $TAR_FILE
    echo "
    Encrypted archive was created.
    "
else
    echo "
    No archive was created.
    Exiting...
    "
fi



echo "
     
    "
echo "
    Please wait while "$BU_MP" is unmounted.
    "
umount "$BU_MP"

echo "
    Bye
    "

exit 0

